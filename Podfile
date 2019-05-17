platform :ios, "11.0"
use_frameworks!
inhibit_all_warnings!

target 'RealTalk' do
 pod 'EzPopup'
  pod 'MessageKit'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Firestore'
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          if target.name == 'MessageKit'
              target.build_configurations.each do |config|
                  config.build_settings['SWIFT_VERSION'] = '4.0'
              end
          end
      end
  end

  pod 'Firebase/Database'
  pod 'ProgressHUD'
  pod 'Firebase/DynamicLinks'
  pod 'Firebase/Messaging'
  pod 'Firebase/AdMob'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Firebase/Analytics'
  pod 'RevealingSplashView'


end
