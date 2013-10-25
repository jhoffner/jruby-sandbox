require 'sandbox/sandbox'
require 'sandbox/version'
require 'fakefs/safe'
require 'timeout'

module Sandbox
  PRELUDE = File.expand_path('../sandbox/prelude.rb', __FILE__).freeze # :nodoc:

  class << self
    def new
      Full.new
    end

    def safe
      Safe.new
    end
  end

  class Safe < Full
    def activate!
      activate_fakefs

      #keep_singleton_methods(:Kernel, KERNEL_S_METHODS)
      #keep_singleton_methods(:Symbol, SYMBOL_S_METHODS)
      #keep_singleton_methods(:String, STRING_S_METHODS)
      keep_singleton_methods(:IO, IO_S_METHODS)

      #keep_methods(:Kernel, KERNEL_METHODS)
      #keep_methods(:NilClass, NILCLASS_METHODS)
      #keep_methods(:Symbol, SYMBOL_METHODS)
      #keep_methods(:TrueClass, TRUECLASS_METHODS)
      #keep_methods(:FalseClass, FALSECLASS_METHODS)
      #keep_methods(:Enumerable, ENUMERABLE_METHODS)
      #keep_methods(:String, STRING_METHODS)

      eval <<-EOF
        class << Kernel
          remove_method '`'
          undef :at_exit
          undef :abort
          undef :autoload
          undef :autoload?
          undef :caller
          undef :exec
          undef :exit
          undef :exit!
          undef :fork
          undef :load
          undef :open
          undef :putc
          undef :puts
          undef :p
          undef :print
          undef :readline
          undef :readlines
          undef :require
          undef :require_relative
          undef :select
          undef :sleep
          undef :spawn
          undef :syscall
          undef :system
          undef :test
          undef :trap
        end

        Kernel.module_eval do
          remove_method '`'
          undef :at_exit
          undef :abort
          undef :autoload
          undef :autoload?
          undef :caller
          undef :exec
          undef :exit
          undef :exit!
          undef :fork
          undef :load
          undef :open
          undef :putc
          undef :puts
          undef :loop
          undef :print
          undef :readline
          undef :readlines
          undef :require
          undef :require_relative
          undef :p
          undef :select
          undef :sleep
          undef :spawn
          undef :syscall
          undef :test
          undef :trap
          undef :system
          undef :set_trace_func
        end
      EOF
    end

    def activate_fakefs
      require 'fileutils'

      # unfortunately, the authors of FakeFS used `extend self` in FileUtils, instead of `module_function`.
      # I fixed it for them
      (FakeFS::FileUtils.methods - Module.methods - Kernel.methods).each do |module_method_name|
        FakeFS::FileUtils.send(:module_function, module_method_name)
      end

      import  FakeFS
      ref     FakeFS::Dir
      ref     FakeFS::File
      ref     FakeFS::FileTest
      import  FakeFS::FileUtils #import FileUtils because it is a module

      eval <<-RUBY
        Object.class_eval do
          remove_const(:Dir)
          remove_const(:File)
          remove_const(:FileTest)
          remove_const(:FileUtils)


          const_set(:Dir,       FakeFS::Dir)
          const_set(:File,      FakeFS::File)
          const_set(:FileUtils, FakeFS::FileUtils)
          const_set(:FileTest,  FakeFS::FileTest)
        end
      RUBY

      FakeFS::FileSystem.clear
    end

    def eval(code, options = {})
      if seconds = options[:timeout]
        Timeout::timeout(options[:timeout]) do
          super code
        end
      else
        super code
      end
    end

    # Keeps
    IO_S_METHODS = %w[
      new
      foreach
      open
    ]

    #  KERNEL_S_METHODS = %w[
    #    Array
    #    binding
    #    block_given?
    #    catch
    #    chomp
    #    chomp!
    #    chop
    #    chop!
    #    eval
    #    fail
    #    Float
    #    format
    #    global_variables
    #    gsub
    #    gsub!
    #    Integer
    #    iterator?
    #    lambda
    #    local_variables
    #    loop
    #    method_missing
    #    proc
    #    rand
    #    raise
    #    scan
    #    split
    #    sprintf
    #    String
    #    srand
    #    sub
    #    sub!
    #    throw
    #  ].freeze
    #
    #  SYMBOL_S_METHODS = %w[
    #    all_symbols
    #  ].freeze
    #
    #  STRING_S_METHODS = %w[
    #    new
    #    try_convert
    #  ].freeze
    #
    #  KERNEL_METHODS = %w[
    #    ==
    #    ===
    #    =~
    #    Array
    #    binding
    #    block_given?
    #    catch
    #    chomp
    #    chomp!
    #    chop
    #    chop!
    #    class
    #    clone
    #    dup
    #    eql?
    #    equal?
    #    eval
    #    fail
    #    Float
    #    format
    #    freeze
    #    frozen?
    #    global_variables
    #    gsub
    #    gsub!
    #    hash
    #    id
    #    initialize_copy
    #    inspect
    #    instance_eval
    #    instance_of?
    #    instance_variables
    #    instance_variable_get
    #    instance_variable_set
    #    instance_variable_defined?
    #    Integer
    #    is_a?
    #    iterator?
    #    kind_of?
    #    lambda
    #    local_variables
    #    loop
    #    method
    #    methods
    #    method_missing
    #    nil?
    #    private_methods
    #    print
    #    proc
    #    protected_methods
    #    public_methods
    #    raise
    #    rand
    #    remove_instance_variable
    #    respond_to?
    #    respond_to_missing?
    #    scan
    #    send
    #    singleton_methods
    #    singleton_method_added
    #    singleton_method_removed
    #    singleton_method_undefined
    #    split
    #    sprintf
    #    String
    #    srand
    #    sub
    #    sub!
    #    taint
    #    tainted?
    #    throw
    #    to_a
    #    to_s
    #    type
    #    untaint
    #    __send__
    #  ].freeze
    #
    #  NILCLASS_METHODS = %w[
    #    &
    #    inspect
    #    nil?
    #    rationalize
    #    to_a
    #    to_c
    #    to_f
    #    to_h
    #    to_i
    #    to_r
    #    to_s
    #    ^
    #    |
    #  ].freeze
    #
    #  SYMBOL_METHODS = %w[
    #    ===
    #    <=>
    #    =~
    #    ==
    #    []
    #    id2name
    #    inspect
    #    to_i
    #    to_int
    #    to_s
    #    to_sym
    #    to_proc
    #    upcase
    #    capitalize
    #    downcase
    #    empty?
    #    encoding
    #    match
    #    next
    #    size
    #    slice
    #    succ
    #    swapcase
    #    intern
    #    casecmp
    #  ].freeze
    #
    #  TRUECLASS_METHODS = %w[
    #    &
    #    to_s
    #    ^
    #    |
    #    inspect
    #  ].freeze
    #
    #  FALSECLASS_METHODS = %w[
    #    &
    #    to_s
    #    ^
    #    |
    #    inspect
    #  ].freeze
    #
    #  ENUMERABLE_METHODS = %w[
    #    all?
    #    any?
    #    chunk
    #    collect
    #    collect_concat
    #    count
    #    cycle
    #    detect
    #    drop
    #    drop_while
    #    each_cons
    #    each_entry
    #    each_slice
    #    each_with_index
    #    each_with_object
    #    entries
    #    find
    #    find_all
    #    group_by
    #    grep
    #    include?
    #    inject
    #    map
    #    max
    #    max_by
    #    member?
    #    min
    #    min_by
    #    member?
    #    minmax
    #    minmax_by
    #    none?
    #    one?
    #    partition
    #    reduce
    #    reject
    #    reverse_each
    #    select
    #    slice_before
    #    sort
    #    sort_by
    #    take
    #    take_while
    #    to_a
    #    zip
    #  ].freeze
    #
    #  STRING_METHODS = %w[
    #    %
    #    *
    #    +
    #    <<
    #    <=>
    #    ==
    #    ===
    #    =~
    #    []
    #    []=
    #    ascii_only?
    #    b
    #    bytes
    #    bytesize
    #    byteslice
    #    capitalize
    #    capitalize!
    #    casecmp
    #    center
    #    chomp
    #    chomp!
    #    chop
    #    chop!
    #    chr
    #    clear
    #    codepoints
    #    concat
    #    count
    #    crypt
    #    chars
    #    delete
    #    delete!
    #    downcase
    #    downcase!
    #    dump
    #    each
    #    each_byte
    #    each_codepoint
    #    each_line
    #    each_char
    #    empty?
    #    encode
    #    encode!
    #    encoding
    #    end_with?
    #    eql?
    #    force_encoding
    #    getbyte
    #    gsub
    #    gsub!
    #    hash
    #    hex
    #    include?
    #    index
    #    initialize
    #    initialize_copy
    #    insert
    #    inspect
    #    intern
    #    length
    #    ljust
    #    lines
    #    lstrip
    #    lstrip!
    #    match
    #    next
    #    next!
    #    oct
    #    ord
    #    partition
    #    prepend
    #    replace
    #    reverse
    #    reverse!
    #    rindex
    #    rjust
    #    rpartition
    #    rstrip
    #    rstrip!
    #    scan
    #    setbyte
    #    size
    #    slice
    #    slice!
    #    split
    #    squeeze
    #    squeeze!
    #    strip
    #    strip!
    #    start_with?
    #    sub
    #    sub!
    #    succ
    #    succ!
    #    sum
    #    swapcase
    #    swapcase!
    #    to_c
    #    to_f
    #    to_i
    #    to_r
    #    to_s
    #    to_str
    #    to_sym
    #    tr
    #    tr!
    #    tr_s
    #    tr_s!
    #    unpack
    #    upcase
    #    upcase!
    #    upto
    #    valid_encoding?
    #    []
    #    []=
    #  ].freeze
  end
end
