local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("cs", {
  -- Class xmldoc
  s("//c", {
    t({"/// <summary>", "/// "}),
    i(1, "Class description"),
    t({"", "/// </summary>"}),
  }),

  -- Method xmldoc
  s("//m", {
    t({"/// <summary>", "/// "}),
    i(1, "Method description"),
    t({"", "/// </summary>", "/// <param name=\""}),
    i(2, "paramName"),
    t("\">"),
    i(3, "Parameter description"),
    t({"</param>", "/// <returns>"}),
    i(4, "Return value description"),
    t("</returns>"),
  }),
})

