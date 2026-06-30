# CodexMeter

一个本地 macOS 菜单栏小应用，用本机 Codex 凭证实时显示 reset credits 额度和到期时间。设计目标是低打扰、iOS 风格、优雅常驻：平时只占用菜单栏一个小位置，点击后展开毛玻璃信息面板。

## 功能

- 从 `~/.codex/auth.json` 读取 `tokens.access_token`
- 请求 `https://chatgpt.com/backend-api/wham/rate-limit-reset-credits`
- 请求 `https://chatgpt.com/backend-api/wham/usage`
- 菜单栏显示 5 小时窗口剩余额度和刷新倒计时
- 弹窗展示 5 小时与 7 天窗口的剩余额度、已用比例、重置时间
- 弹窗展示每张 credit 的 `status`、`title`、`granted_at`、`expires_at`
- 所有时间按上海时间显示
- 自动按系统语言显示：中文系统为中文，其他系统为纯英文
- 每 60 秒自动刷新，支持手动刷新
- 401 时显示“凭证失效或没带对 Authorization header”
- 右键菜单支持刷新和退出

## 运行

```bash
cd "/Users/tao/Documents/New project/CodexQuotaIsland"
swift run
```

## 生成未签名 DMG

```bash
cd "/Users/tao/Documents/New project/CodexQuotaIsland"
bash scripts/package_dmg.sh
```

输出文件位于 `dist/CodexMeter-0.1.0-unsigned.dmg`。这是未签名、未公证版本，用户第一次打开需要右键打开或在“系统设置 > 隐私与安全性”中手动允许。

默认使用 `Packaging/AppIconSource.png` 作为 `.app` 图标，不影响菜单栏状态图标。也可以临时指定其他图标：

```bash
ICON_SOURCE="/path/to/icon.png" bash scripts/package_dmg.sh
```
