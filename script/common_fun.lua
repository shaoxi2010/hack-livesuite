require("ini_fun")

function LoadC_Fun(modelpath, funcName)
  local Reg = package.loadlib(modelpath, funcName)
  if Reg then
    print("Register" .. modelpath .. " " .. funcName .. " Sucess!")
    Reg()
  else
    print("Register" .. modelpath .. " " .. funcName .. " Failed!")
  end
end
