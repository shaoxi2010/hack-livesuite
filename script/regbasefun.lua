package.path = package.path .. ";./?.lhs;../?.lhs"
require("common_fun")

function Reg_BaseFun()
  LoadC_Fun("./luaBase.dll", "l_RegAllFun")
  LoadC_Fun("./luaeFex.dll", "l_RegAllFun")
end

Reg_BaseFun()
