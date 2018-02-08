require 'llvm/core'
require 'llvm/execution_engine'
require 'llvm/transforms/scalar'
require 'parser'

LLVM.init_jit


module Kaleidoscope
  class Scopes
    def initialize
      @scopes = [{}]
    end

    def push
      @scopes.push({})
    end

    def pop
      @scopes.pop()
    end

    def get(name, level=0)
      return if -level >= @scopes.length
      @scopes[level - 1][name] || get(name, level - 1)
    end

    def [](name)
      get(name)
    end

    def []=(name, value)
      @scopes.last[name] = value
    end
  end


  class NumLiteral
    def emit(llvm_module, builder, scopes)
      LLVM::Double(val.to_f)
    end
  end


  class Identifier
    def emit(llvm_module, builder, scopes)
      raise "ERROR! Unknown variable #{name}" unless scopes[name]
      builder.load(scopes[name], name)
    end
  end


  class OpSequence
    def emit(llvm_module, builder, scopes)
      rights.reduce(left.emit(llvm_module, builder, scopes)) do |left_emit, op_right|
        right_emit = op_right.right.emit(llvm_module, builder, scopes)

        case op_right.op
          when '+'; builder.fadd(left_emit, right_emit)
          when '-'; builder.fsub(left_emit, right_emit)
          when '*'; builder.fmul(left_emit, right_emit)
          when '/'; builder.fdiv(left_emit, right_emit)
          when '<'; builder.ui2fp(builder.fcmp(:ult, left_emit, right_emit), LLVM::Double)
          when '>'; builder.ui2fp(builder.fcmp(:ugt, left_emit, right_emit), LLVM::Double)
        end
      end
    end
  end


  class Cond
    def emit(llvm_module, builder, scopes)
      orig_block = builder.insert_block
      merge_block = orig_block.parent.basic_blocks.append()

      block_emits = [then_val, else_val].inject({}) do |h, expr|
        builder.position_at_end(orig_block.parent.basic_blocks.append())
        expr_emit = expr.emit(llvm_module, builder, scopes) # note: can point builder to new block
        builder.br(merge_block)
        h.merge!(builder.insert_block => expr_emit)
      end

      builder.position_at_end(orig_block)
      test_emit = builder.fcmp(:une, test.emit(llvm_module, builder, scopes), LLVM::Double(0.0))
      builder.cond(test_emit, *block_emits.keys)

      builder.position_at_end(merge_block)
      builder.phi(LLVM::Double, block_emits)
    end
  end


  class FuncCall
    def emit(llvm_module, builder, scopes)
      func = llvm_module.functions[name]

      raise "ERROR! Unknown function #{name}" unless func
      raise "ERROR! Incorrect number of arguments to function #{name} " +
          "(expected #{func.params.size}; got #{args.length})" unless func.params.size == args.length

      builder.call(func, *args.map{|a| a.emit(llvm_module, builder, scopes) })
    end
  end


  class FuncDef
    def emit(llvm_module, builder, scopes)
      raise "ERROR! Redefinition of function #{name}" if llvm_module.functions.named(name)
      params.group_by(&:itself).each do |p, ps|
        raise "ERROR! Redefinition of parameter #{p} in function #{name}" if ps.length > 1
      end

      orig_block = builder.insert_block
      scopes.push()

      func = llvm_module.functions.add(name, [LLVM::Double] * params.length, LLVM::Double)
      entry = LLVM::BasicBlock.create(func, 'entry')
      builder.position_at_end(entry)

      func.params.each_with_index do |p, i|
        ptr = builder.alloca(p)
        builder.store(p, ptr)
        p.name = self.params[i]
        scopes[p.name] = ptr
      end

      builder.ret(body.emit(llvm_module, builder, scopes))
      func.verify

      scopes.pop()
      builder.position_at_end(orig_block)

      func
    end
  end


  def self.compile_run(src)
    src = parse(src) if src.is_a?(String)

    llvm_module = LLVM::Module.new('Kaleidoscope')
    builder = LLVM::Builder.new
    scopes = Scopes.new

    main = llvm_module.functions.add('main', [], LLVM::Double)
    builder.position_at_end(LLVM::BasicBlock.create(main, 'entry'))
    retval = src.inject(nil){|val, s| s.emit(llvm_module, builder, scopes) }
    raise "ERROR! No return value" unless retval
    builder.ret(retval)

    llvm_module.verify
    #llvm_module.dump

    jit = LLVM::JITCompiler.new(llvm_module)
    jit.run_function(llvm_module.functions['main']).to_f(LLVM::Double.type)
  end

end
