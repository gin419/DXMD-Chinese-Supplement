# Deus Ex: Mankind Divided — Steam v1.19 中文补全工程

本工程用于在 3DM 轩辕 v4.5 汉化基础上，补齐 Steam v1.19（build 801.0）遗漏或未覆盖的文本。

## 当前状态

- 本机游戏：`G:\\SteamLibrary\\steamapps\\common\\Deus Ex Mankind Divided`
- 本机检测到：`retail/DXMD.exe` 文件版本 `1.19`；完整版本号应以 Steam 当前安装内容为准。
- 已确认的基础方案：3DM 轩辕汉化 v4.5。其说明以 v1.16 为基准，并声称理论支持后续版本；不能直接视为 v1.19 的完整验证。
- 已导入 `downloads/DXMD_full_chinese_text.zip`，并将已解析的中文数据保存为 `translation/strings.json`；未覆盖游戏文件。
- 已从本机 `Game.layer.0.all.archive` 建立索引，并扫描出 3,367 个可解析 BILR 文本资源、572,311 条文本条目。
- 中文包校验结果：3,626 个 textlist、96,670 条文本，其中 85,878 条含中文；JSON 可解析，另含 92 条字幕记录。
- 已完成人工语义校订第一轮：修订 879 条高频对白和明显机翻句，统一核心人名、组织名、设施名及术语；时间码和控制标记数量保持不变。
- 已生成 `dist/` 下的 v1.19 文本覆盖包和旧版兼容包。当前 Windows 11 不应使用包内的 `version.dll`，需要新版框架的 `bink2w64.dll`。
- 已生成可转发的一体化安装包：`dist/DXMD-Chinese-Standalone-v1.19.zip`。其中包含新版框架 DLL、中文文本、字体、配置、自动备份安装器和卸载器。

## 目标

1. 获取并记录基础语言数据。
2. 使用 DXMD-Translations 框架提取/加载 v1.19 文本。
3. 对比基础数据与 v1.19 字符串，建立 `translation/missing.json`。
4. 人工翻译、校对并测试字体、占位符、换行、字幕和 DLC 文本。
5. 生成可回滚的 `retail` 覆盖包，并保留原始文件哈希。

## 重要限制

翻译框架本身只负责加载替换字符串，不等于中文翻译包。本次导入的附件明确是测试翻译；本轮先修订高频和明显错误，仍需结合英文原文及实机流程继续校对，信息链和 Breach 角色名等界面已有遮挡问题。当前 `dist` 包可用于后续实机测试，但还不能宣称“完整汉化”。

## 外部参考

- 3DM v4.5：<https://dl.3dmgame.com/patch/96777.html>
- v1.19 已测试的翻译框架：<https://github.com/SeanPesce/DXMD-Translations/releases>
- 中文测试文本包：<https://github.com/SeanPesce/DXMD-Translations/issues/17>

