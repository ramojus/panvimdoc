PANDOC_VERSION:must_be_at_least("3.0")

local pipe = pandoc.pipe
local stringify = (require("pandoc.utils")).stringify
local text = pandoc.text

function P(s)
  require("scripts.logging").temp(s)
end

-- custom writer for pandoc

local unpack = unpack or table.unpack
local format = string.format
local stringify = pandoc.utils.stringify
local layout = pandoc.layout
local to_roman = pandoc.utils.to_roman_numeral

function string.starts_with(str, starts)
  return str:sub(1, #starts) == starts
end

function string.ends_with(str, ends)
  return ends == "" or str:sub(-#ends) == ends
end

-- Character escaping
local function escape(s, in_attribute)
  return s
end

function indent(s, fl, ol)
  local ret = {}
  local i = 1
  for l in s:gmatch("[^\r\n]+") do
    if i == 1 then
      ret[i] = fl .. l
    else
      ret[i] = ol .. l
    end
    i = i + 1
  end
  return table.concat(ret, "\n")
end

Writer = pandoc.scaffolding.Writer

local function inlines(ils)
  local buff = {}
  for i = 1, #ils do
    local el = ils[i]
    buff[#buff + 1] = Writer[pandoc.utils.type(el)][el.tag](el)
  end
  return table.concat(buff)
end

local function blocks(bs, sep)
  local dbuff = {}
  for i = 1, #bs do
    local el = bs[i]
    dbuff[#dbuff + 1] = Writer[pandoc.utils.type(el)][el.tag](el)
  end
  return table.concat(dbuff, sep)
end

local PROJECT = ""
local TREESITTER = false
local TOC = false
local VIMVERSION = "0.9.0"
local DESCRIPTION = ""
local DEDUP_SUBHEADINGS = false
local IGNORE_RAWBLOCKS = true
local DATE = nil

local CURRENT_HEADER = nil

local HEADER_COUNT = 1
local toc = {}
local links = {}

local function osExecute(cmd)
  local fileHandle = assert(io.popen(cmd, "r"))
  local commandOutput = assert(fileHandle:read("*a"))
  local returnTable = { fileHandle:close() }
  return commandOutput, returnTable[3] -- rc[3] contains returnCode
end

local function renderTitle()
  local t = {}
  local function add(s)
    table.insert(t, s)
  end
  local vim_doc_title = PROJECT .. ".txt"
  local vim_doc_title_tag = "*" .. vim_doc_title .. "*"
  local project_description = DESCRIPTION or ""
  if not project_description or #project_description == 0 then
    local vim_version = VIMVERSION
    if vim_version == nil then
      vim_version = osExecute("nvim --version"):gmatch("([^\n]*)\n?")()
      if string.find(vim_version, "-dev") then
        vim_version = string.gsub(vim_version, "(.*)-dev.*", "%1")
      end
      if vim_version == "" then
        vim_version = osExecute("vim --version"):gmatch("([^\n]*)\n?")()
        vim_version = string.gsub(vim_version, "(.*) %(.*%)", "%1")
      end
      if vim_version == "" then
        vim_version = "vim"
      end
    elseif vim_version == "vim" then
      vim_version = osExecute("vim --version"):gmatch("([^\n]*)\n?")()
    end

    local date = DATE
    if date == nil then
      date = os.date("%Y %B %d")
    end
    local m = "For " .. vim_version
    local r = "Last change: " .. date
    local n = math.max(0, 78 - #vim_doc_title_tag - #m - #r)
    local s = string.rep(" ", math.floor(n / 2))
    project_description = s .. m .. s .. r
  end
  local padding_len = math.max(0, 78 - #vim_doc_title_tag - #project_description)
  add(vim_doc_title_tag .. string.rep(" ", padding_len) .. project_description)
  add("")
  return table.concat(t, "\n")
end

local function renderToc()
  if TOC then
    local t = {}
    local function add(s)
      table.insert(t, s)
    end
    add(string.rep("=", 78))
    local l = "Table of Contents"
    local tag = "*" .. PROJECT .. "-" .. string.gsub(string.lower(l), "%s", "-") .. "*"
    add(l .. string.rep(" ", 78 - #l - #tag) .. tag)
    add("")
    for _, elem in pairs(toc) do
      local level, item, link = elem[1], elem[2], elem[3]
      if level == 1 then
        local padding = string.rep(" ", 78 - #item - #link)
        add(item .. padding .. link)
      elseif level == 2 then
        local padding = string.rep(" ", 74 - #item - #link)
        add("  - " .. item .. padding .. link)
      end
    end
    add("")
    return table.concat(t, "\n")
  else
    return ""
  end
end

local function renderNotes()
  local t = {}
  local function add(s)
    table.insert(t, s)
  end
  if #links > 0 then
    local left = HEADER_COUNT .. ". Links"
    local right = "links"
    local right_link = string.format("|%s-%s|", PROJECT, right)
    right = string.format("*%s-%s*", PROJECT, right)
    local padding = string.rep(" ", 78 - #left - #right)
    table.insert(toc, { 1, left, right_link })
    add(string.rep("=", 78) .. "\n" .. string.format("%s%s%s", left, padding, right))
    add("")
    for i, v in ipairs(links) do
      add(i .. ". *" .. v.caption .. "*" .. ": " .. v.src)
    end
  end
  return table.concat(t, "\n") .. "\n"
end

function renderFooter()
  return [[Generated by panvimdoc <https://github.com/kdheepak/panvimdoc>

vim:tw=78:ts=8:noet:ft=help:norl:]]
end

Writer.Pandoc = function(doc, opts)
  PROJECT = doc.meta.project
  TREESITTER = doc.meta.treesitter
  TOC = doc.meta.toc
  VIMVERSION = doc.meta.vimversion
  DESCRIPTION = doc.meta.description
  DEDUP_SUBHEADINGS = doc.meta.dedupsubheadings
  IGNORE_RAWBLOCKS = doc.meta.ignorerawblocks
  HEADER_COUNT = HEADER_COUNT + doc.meta.incrementheadinglevelby
  DATE = doc.meta.date
  local d = blocks(doc.blocks)
  local toc = renderToc()
  local notes = renderNotes()
  local title = renderTitle()
  local footer = renderFooter()
  return { title, layout.blankline, toc, d, notes, layout.blankline, footer }
end

Writer.Block.Header = function(el)
  local lev = el.level
  local s = stringify(el)
  local attr = el.attr
  local left, right, right_link, padding
  if lev == 1 then
    left = string.format("%d. %s", HEADER_COUNT, s)
    right = string.lower(string.gsub(s, "%s", "-"))
    CURRENT_HEADER = right
    right_link = string.format("|%s-%s|", PROJECT, right)
    right = string.format("*%s-%s*", PROJECT, right)
    padding = string.rep(" ", 78 - #left - #right)
    table.insert(toc, { 1, left, right_link })
    s = string.format("%s%s%s", left, padding, right)
    HEADER_COUNT = HEADER_COUNT + 1
    s = string.rep("=", 78) .. "\n" .. s
    return "\n" .. s .. "\n\n"
  end
  if lev == 2 then
    left = string.upper(s)
    right = string.lower(string.gsub(s, "%s", "-"))
    if DEDUP_SUBHEADINGS then
      right_link = string.format("|%s-%s-%s|", PROJECT, CURRENT_HEADER, right)
      right = string.format("*%s-%s-%s*", PROJECT, CURRENT_HEADER, right)
    else
      right_link = string.format("|%s-%s|", PROJECT, right)
      right = string.format("*%s-%s*", PROJECT, right)
    end
    padding = string.rep(" ", 78 - #left - #right)
    table.insert(toc, { 2, s, right_link })
    s = string.format("%s%s%s", left, padding, right)
    return "\n" .. s .. "\n\n"
  end
  if lev == 3 then
    left = string.upper(s)
    return "\n" .. left .. " ~" .. "\n\n"
  end
  if lev == 4 then
    left = ""
    right = string.gsub(s, "{.+}", "")
    right = string.gsub(right, "%[.+%]", "")
    right = string.gsub(right, "^%s*(.-)%s*$", "%1")
    right = string.gsub(right, "%s", "-")
    right = string.format("*%s-%s*", PROJECT, right)
    if attr.doc then
      right = right .. " *" .. attr.doc .. "*"
    end
    padding = string.rep(" ", 78 - #left - #right)
    local r = string.format("%s%s%s", left, padding, right)
    return "\n" .. r .. "\n\n"
  end
  if lev >= 5 then
    left = string.upper(s)
    return "\n" .. left .. "\n\n"
  end
end

Writer.Block.Para = function(el)
  local s = inlines(el.content)
  local t = {}
  local current_line = ""
  for word in string.gmatch(s, "([^%s]+)") do
    if string.match(word, "[.]") and #word == 1 then
      current_line = current_line .. word
    elseif (#current_line + #word) > 78 then
      table.insert(t, current_line)
      current_line = word
    elseif #current_line == 0 then
      current_line = word
    else
      current_line = current_line .. " " .. word
    end
  end
  table.insert(t, current_line)
  return table.concat(t, "\n") .. "\n\n"
end

Writer.Block.OrderedList = function(items)
  local buffer = {}
  local i = 1
  items.content:map(function(item)
    table.insert(buffer, ("%s. %s"):format(i, blocks(item)))
    i = i + 1
  end)
  return "\n" .. table.concat(buffer) .. "\n\n"
end

Writer.Block.BulletList = function(items)
  local buffer = {}
  items.content:map(function(item)
    table.insert(buffer, indent(blocks(item, "\n"), "- ", "    "))
  end)
  return "\n" .. table.concat(buffer, "\n") .. "\n\n"
end

Writer.Block.DefinitionList = function(items)
  local buffer = {}
  for _, item in pairs(items) do
    local k, v = next(item)
    table.insert(buffer, k .. string.rep(" ", 78 - 40 + 1 - #k) .. table.concat(v, "\n"))
  end
  return "\n" .. table.concat(buffer, "\n") .. "\n\n"
end

Writer.Block.CodeBlock = function(el)
  local attr = el.attr
  local s = el.text
  if attr.class == "vimdoc" then
    return s
  else
    local lang = ""
    if TREESITTER and #attr.classes > 0 then
      lang = attr.classes[1]
    end
    local t = {}
    for line in s:gmatch("([^\n]*)\n?") do
      table.insert(t, "    " .. escape(line))
    end
    return ">" .. lang .. "\n" .. table.concat(t, "\n") .. "\n<\n\n"
  end
end

Writer.Inline.Str = function(el)
  local s = stringify(el)
  if string.starts_with(s, "(http") and string.ends_with(s, ")") then
    return " <" .. string.sub(s, 2, #s - 2) .. ">"
  else
    return escape(s)
  end
end

Writer.Inline.Space = function()
  return " "
end

Writer.Inline.SoftBreak = function()
  return "\n"
end

Writer.Inline.LineBreak = function()
  return "\n"
end

Writer.Inline.Emph = function(s)
  return "_" .. stringify(s) .. "_"
end

Writer.Inline.Strong = function(s)
  return "**" .. stringify(s) .. "**"
end

Writer.Inline.Subscript = function(s)
  return "_" .. stringify(s)
end

Writer.Inline.Superscript = function(s)
  return "^" .. stringify(s)
end

Writer.Inline.SmallCaps = function(s)
  return stringify(s)
end

Writer.Inline.Strikeout = function(s)
  return "~" .. stringify(s) .. "~"
end

Writer.Inline.Link = function(el)
  local s = inlines(el.content)
  local tgt = el.target
  local tit = el.title
  local attr = el.attr
  if string.starts_with(tgt, "https://neovim.io/doc/") then
    return "|" .. s .. "|"
  elseif string.starts_with(tgt, "#") then
    return "|" .. PROJECT .. "-" .. s:lower():gsub("%s", "-") .. "|"
  elseif string.starts_with(s, "http") then
    return s
  else
    return s .. " <" .. tgt .. ">"
  end
end

Writer.Inline.Image = function(el)
  links[#links + 1] = { caption = inlines(el.caption), src = el.src }
end

Writer.Inline.Code = function(el)
  return "`" .. escape(stringify(el)) .. "`"
end

Writer.Inline.InlineMath = function(s)
  return "`" .. escape(stringify(s)) .. "`"
end

Writer.Inline.DisplayMath = function(s)
  return "`" .. escape(stringify(s)) .. "`"
end

Writer.Inline.SingleQuoted = function(s)
  return "'" .. stringify(s) .. "'"
end

Writer.Inline.DoubleQuoted = function(s)
  return "\"" .. stringify(s) .. "\""
end

Writer.Inline.Note = function(s)
  return stringify(s)
end

Writer.Inline.Null = function(s)
  return ""
end

Writer.Inline.Span = function(s, attr)
  return stringify(s)
end

Writer.Inline.RawInline = function(el)
  if format == "html" then
    if str == "<b>" then
      return ""
    elseif str == "</b>" then
      return " ~"
    elseif str == "<i>" or str == "</i>" then
      return "_"
    elseif str == "<kbd>" or str == "</kbd>" then
      return ""
    else
      return str
    end
  else
    return ""
  end
end

Writer.Inline.Cite = function(el)
  if #cs == 1 then
    return string.sub(s, 2, (#s - 1))
  else
    return inlines(s)
  end
end

Writer.Block.Plain = function(el)
  return inlines(el.content)
end

Writer.Block.RawBlock = function(el)
  local fmt = el.format
  local str = el.text
  if fmt == "html" then
    if string.starts_with(str, "<!--") then
      return ""
    elseif str == "<p>" or str == "</p>" then
      return ""
    elseif str == "<details>" or str == "</details>" then
      return ""
    elseif str == "<summary>" then
      return ""
    elseif str == "</summary>" then
      return " ~\n\n"
    elseif IGNORE_RAWBLOCKS then
      return ""
    else
      return str
    end
  else
    return ""
  end
end

Writer.Block.Table = function(el)
  return pandoc.write(pandoc.Pandoc({ el }), "plain")
end

Writer.Block.Div = function(el)
  -- TODO: Add more special features here
  return blocks(el.content)
end

Writer.Block.Figure = function(el)
  return blocks(el.content)
end

Writer.Block.BlockQuote = function(el)
  local lines = {}
  for line in blocks(el.content):gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return "\n  " .. table.concat(lines, "\n  ") .. "\n"
end

Writer.Block.HorizontalRule = function()
  return string.rep("-", 78)
end

Writer.Block.LineBlock = function(el)
  local buffer = {}
  el.content:map(function(item)
    table.insert(buffer, table.concat({ "| ", inlines(item) }))
  end)
  return "\n" .. table.concat(buffer, "\n") .. "\n"
end
