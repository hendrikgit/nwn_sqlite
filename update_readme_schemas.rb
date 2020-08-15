#!/usr/bin/env ruby

tables = File.read('schemas.sqlite').scan(/^pragma table_info\('(\w+)'\);/).flatten

schemas_md = "Tables\n" + tables.map{|t| "* [#{t}](##{t})"}.join("\n") + "\n\n"

input = ARGF.read
idx = 0
for line in input.lines
  if line.start_with?('cid')
    schemas_md += "```\n\n" if idx > 0
    schemas_md += "### #{tables[idx]}\n```\n"
    idx += 1
  end
  schemas_md += line.sub(/ +$/, '')
end
schemas_md += '```'

File.write('readme.md', File.read('readme.md').sub(/^Tables.*/m, schemas_md))

puts "readme.md updated"
