#
#  Be sure to run `pod spec lint PayUmoney_PnP.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         		= "PayUIndia-OlaMoney"
  s.version   		    = "1.0.0"
  s.license             = "MIT"
  s.homepage            = "https://github.com/payu-intrepos/payu-olamoney-ios"
  s.author              = { "PayUbiz" => "contact@payu.in"  }

  s.summary             = "A lightweight SDK which supports payments via OlaMoney (Postpaid + Wallet)"
  s.description         = "A lightweight SDK which supports payments via OlaMoney (Postpaid + Wallet)"

  s.source              = { :git => "https://github.com/payu-intrepos/payu-olamoney-ios.git",
                            :tag => "#{s.name}_#{s.version}"
                          }
  
  s.ios.deployment_target = "10.0"
  s.vendored_frameworks = 'Framework/PayUOlaMoneySDK.framework'
  s.dependency            'PayUIndia-Logger', '1.0.1'
  s.dependency            'PayUIndia-Networking', '1.0.1'

end