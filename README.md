# Miruna

よく開いてしまうアプリを、閉じてからしばらくのあいだ一拍置いて見直すためのアシスタントです。

対象アプリを起動して閉じたあと、警告期間（デフォルトは1時間）以内にまた開こうとすると、「前回の起動から1時間経っていません。本当に開きますか？」と確認します。はいを押せば開けます。いいえならホームに戻ります。警告期間はアプリごとに変えられます。

## 対応状況

- **Android**: フォアグラウンド検知と確認ダイアログまで実装しています。
- **iOS**: 設定画面のみです。OS の制約のため、他アプリ起動への介入は未対応です。
- **macOS**: 設定画面の確認用です。他アプリの監視は動きません。

## 必要なもの

- Flutter 3.13 以降（PATH にない場合は、リポジトリ直下の `.sdk/flutter` を使います）
- Android 8（API 26）以降
- macOS で画面確認する場合は、フルインストールの Xcode

## 始め方

Flutter が PATH にあれば `flutter`、なければ次のパスを使います。

```bash
.sdk/flutter/bin/flutter pub get
.sdk/flutter/bin/flutter test
.sdk/flutter/bin/flutter run
```

このシェルだけ `flutter` と打ちたいときは:

```bash
export PATH="$PWD/.sdk/flutter/bin:$PATH"
```

## macOS で画面を確認する

監視機能は Android 専用です。macOS ではオンボーディングや設定画面だけを確認できます。

初回だけ macOS 用プロジェクトを足します（リポジトリに `macos/` が無い場合）。

```bash
.sdk/flutter/bin/flutter create --platforms=macos .
```

Xcode が入っていなければ App Store から入れ、初回セットアップを済ませます。

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
.sdk/flutter/bin/flutter doctor
```

起動:

```bash
.sdk/flutter/bin/flutter run -d macos
```

## Android テスト端末へのインストール

このプロジェクトは Android / iOS 向けです。接続されているのが macOS や Chrome だけのときは、上の macOS 向け手順を使うか、Android 実機を繋いでください。

1. Android Studio などで Android SDK を入れ、`flutter doctor` の Android toolchain を通す
2. 端末（Android 8 以降）で USB デバッグを有効にし、USB（またはワイヤレスデバッグ）で接続する
3. 認識を確認してインストールする

```bash
.sdk/flutter/bin/flutter doctor
.sdk/flutter/bin/flutter doctor --android-licenses
.sdk/flutter/bin/flutter devices
.sdk/flutter/bin/flutter run
```

端末が複数あるときはデバイス ID を指定します。

```bash
.sdk/flutter/bin/flutter run -d <device_id>
```

APK を直接入れる場合:

```bash
.sdk/flutter/bin/flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Android では初回に次の権限を案内します。

- 使用状況へのアクセス
- 他のアプリの上に表示
- 通知（監視サービスの常駐）
- ユーザー補助（推奨。検知が速くなります）
- 電池の最適化から除外（推奨）
