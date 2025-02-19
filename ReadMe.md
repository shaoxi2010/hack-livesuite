# 目的
研究研究全志的镜像是如何实现usb烧录过程的
上位机程序[livesuite](https://github.com/linux-sunxi/sunxi-livesuite)

# 基本分析
livesuite是一个基于Qt4的程序，从程序结构上看可以看到它使用lua脚本进行烧录过程控制，通过调用底层库进行烧录操作。
通过file分析：
1. 发现其dll就是一个动态库，只是将后缀定义为dll
2. aultools.fex实际上是一个lua字节文件

# luaeFex.dll
通过观察大致可以发现，它是一个lua动态库程序,但他并没有直接被调用注册，目前还没有发现如何调用它，但可以确定的是，它是一个lua动态库程序。
由于lua库装载必然使用luaopen_base函数中寻找发现它存在于LiveProc.Plg中可以看到Lua版本为5.1。
在通过字符串搜索发现luaeFex调用自regbasefun.lua中，并没有直接注册为lua库。
## 逆向lua字节码
通过 java -jar unluac.jar script/regbasefun.lua 
可以得到regbasefun.lua的反编译结果，根据代码可以知道，它通过调用LoadC_Fun函数来加载lua动态库，并注册其中的函数。
```
package.path = package.path .. ";./?.lhs;../?.lhs"
require("common_fun")

function Reg_BaseFun()
  LoadC_Fun("./luaBase.dll", "l_RegAllFun")
  LoadC_Fun("./luaeFex.dll", "l_RegAllFun")
end

Reg_BaseFun()
```
## 获取lua注册方法
通过LoadC_Fun函数可以知道，它通过调用l_RegAllFun函数来注册lua函数，因此我们需要反编译luaeFex.dll
通过IDA反编译luaeFex.dll，找到l_RegAllFun函数
```
int __cdecl l_RegAllFun(lua_State *L)
{
  lua_pushcclosure(L, l_Fex_Open, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_Open");
  lua_pushcclosure(L, l_Fex_Close, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_Close");
  lua_pushcclosure(L, l_Fex_Query, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_Query");
  lua_pushcclosure(L, l_Fex_Send, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_Send");
  lua_pushcclosure(L, l_Fex_Recv, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_Recv");
  lua_pushcclosure(L, l_Fex_transmit_receive, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_transmit_receive");
  lua_pushcclosure(L, l_Fex_command, 0LL);
  lua_setfield(L, 0xFFFFD8EELL, "Fex_command");
  return 0;
}
```
通过分析可以知道，它注册了Fex_Open、Fex_Close、Fex_Query、Fex_Send、Fex_Recv、Fex_transmit_receive、Fex_command这些函数，因此我们可以通过调用这些函数来实现烧录过程，其内部实现为全志私有的USB[协议](https://linux-sunxi.org/FEL/Protocol)，在对应平台实现这些函数即可实现同一镜像在不同系统下烧录。

## 寻找执行烧录程序
1. 通过搜索Fex_Open字符串，可以找到位于在镜像的autotools.fex中，这里以melis4.0为例子。
2. 继续寻找可以发现在imgdec_fun.lua中实现了镜像解析函数，可以发现Img_DownItemToLocal实现了最终的镜像解析。
3. 查找Img_DownItemToLocal字符串，可以发现它处于LiveProc.Plg中，通过寻找打包镜像的maintype："UPFLYTLS",subtype： "xxxxxxxxxxxxxxxx"，找到对应脚本程序
```
u32 __cdecl ASuitImage::GetToolsFromImage(ASuitImage *const this, const char *image_path, const char *tools_path)
{
  const char *v3; // rax
  int nError; // [rsp+28h] [rbp-118h]
  char szInfo[264]; // [rsp+30h] [rbp-110h] BYREF
  unsigned __int64 v8; // [rsp+138h] [rbp-8h]

  v8 = __readfsqword(0x28u);
  lua_getfield(this->_luaState, 4294957294LL, "Img_DownItemToLocal");
  lua_type(this->_luaState, 0xFFFFFFFFLL);
  lua_pushstring(this->_luaState, image_path);
  lua_pushstring(this->_luaState, "UPFLYTLS");
  lua_pushstring(this->_luaState, "xxxxxxxxxxxxxxxx");
  lua_pushstring(this->_luaState, tools_path);
  nError = lua_pcall(this->_luaState, 4LL, 0LL, 0LL);
  if ( !nError )
    return 0;
  memset(szInfo, 0, 260);
  v3 = (const char *)lua_tolstring(this->_luaState, 0xFFFFFFFFLL, 0LL);
  sprintf(szInfo, "pcall FAILED %s %d %d", v3, nError, 307);
  PhoenixDebug::DebugMsg("\n%s\n", szInfo);
  return 309;
}
```
4. 在image_nor.cfg中可以发现对应key为aultools.fex，推测aultls32.fex应该是给32位系统准备的。
后续应该就是通过主程序回调这部分实现进行烧录操作了，不在需要继续分析。


# 自定义烧录过程
从当前分析上看，要修改usb烧录过程主要是修改aultools.fex文件即可，但如何修改这个文件呢？

由于luaBase.dll实际上是闲了lua_dump等方法，我们可以用它来造一个luac，这样就可以尽可能的保证环境一致，不能保证完全一样。
1. 首先将luaBase.dll拷贝一份放到当前目录，并重命名为liblua.so
2. 执行gcc luacompile.c -o luac -I lua-5.1/  -llua -L $(pwd) -ldl生成luac
3. 执行LD_LIBRARY_PATH=$(pwd) ./luac regbasefun.lua regbasefun.luac生成regbasefun.luac

# 烧录过程
烧录过程分为两个阶段：
1. 烧录fes1并初始化内存
2. 烧录uboot和其他组建，将镜像下载到设备
