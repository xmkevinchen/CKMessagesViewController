# CKMessagesKit

> A Swiftified, open source, Protocol-Orietated Messages UI Kit for iOS




## Design Goals
* [SOLID](https://en.wikipedia.org/wiki/SOLID_(object-oriented_design)) Principle
* [Protocol-Orientated Programming](https://developer.apple.com/videos/play/wwdc2015/408/) to follow the SOLID Principle
* [MVC](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) design pattern
* Easy customization and extension for clients


##  Requirements
* Swift 3.0
* Xcode 8
* iOS 8

## Installation

### [Carthage](https://github.com/Carthage/Carthage) (Recommended)

```
github "xmkevinchen/CKMessagesKit"
```

### [CocoaPods](https://cocoapods.org/)

```
platform :ios, '9.0'

target 'Your target' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'CKMessagesKit', :git => 'https://github.com/xmkevinchen/CKMessagesKit.git', :branch => 'master'


end

post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
      end
  end
end

```



## Getting Started

Checkout the **Sample** project in the repository

Use Carthage to download the dependencies of the Sample project


## TODO
1. More build-in message types support
    * Image
    * Video
    * Location
2. ~~Submit CKMessagesKit to CocoaPods, needs to wait CocoaPods 1.1.0.rc.2 version~~
3. Async message content presenting mechanism.
4. Try to use `CKViewLayout` protocol to layout message cell, instead of using massive AutoLayout constraint.


## Current version

### 1.2
- Refactor the message size calculation logic, centralize them into the `CKMessageSizeCalculator`, remove the logic from `CKMessagesViewLayout`
- When connect to hardware keyboard, `CKMessagesView` now just update its contentInset with input toolbar size

### [Release Notes](CHANGELOG.md)

<hr/>
Finally, CKMessagesKit was inspired by [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) and [LayerKit](https://layer.com/). Thanks to Authors and Contributors

However, there're some reasons pushing me to create CKMessagesKit by myself

* Pure Swift implementation, written in Swift 3.0
* Nested collection UI presentation support, like using `UICollectionView`, `UITableView` in `UICollectionViewCell` to show such **Data Card** UI design
* Protocol-Orientated Programming & SOLID Principle strictly follows
