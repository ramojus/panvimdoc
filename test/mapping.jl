@testset "markdown" begin
  doc = test_pandoc(
    raw"""
#### :FnlCompile[!] {doc=:FnlCompile}

Diff compiles all indexed fennel files

#### :FnlCompile[!]

Diff compiles all indexed fennel files

#### :[range]CommandName {doc=CommandName}

#### :[range]CommandName
    """;
    toc = false,
    demojify = true,
  )
  @test doc == raw"""
*test.txt*                                                    Test Description

:FnlCompile[!]                                                   *:FnlCompile*

Diff compiles all indexed fennel files


:FnlCompile[!]                                              *test-:FnlCompile*

Diff compiles all indexed fennel files


:[range]CommandName                                              *CommandName*


:[range]CommandName                                        *test-:CommandName*

Generated by panvimdoc <https://github.com/kdheepak/panvimdoc>

vim:tw=78:ts=8:noet:ft=help:norl:
"""

  doc = test_pandoc(
    raw"""
#### :FnlCompile[!] {doc=:FnlCompile}

Diff compiles all indexed fennel files

#### :FnlCompile[!]

Diff compiles all indexed fennel files

#### :[range]CommandName {doc=CommandName}

#### :[range]CommandName
    """;
    toc = false,
    demojify = true,
    doc_mapping = false,
  )
  @test doc == raw"""
*test.txt*                                                    Test Description

:FNLCOMPILE[!]

Diff compiles all indexed fennel files


:FNLCOMPILE[!]

Diff compiles all indexed fennel files


:[RANGE]COMMANDNAME


:[RANGE]COMMANDNAME

Generated by panvimdoc <https://github.com/kdheepak/panvimdoc>

vim:tw=78:ts=8:noet:ft=help:norl:
"""
end
