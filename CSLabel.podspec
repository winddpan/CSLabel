#
# Be sure to run `pod lib lint CSLabel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CSLabel"
  s.version          = "1.0.2"
  s.summary          = "HTML -> TextKit displayer."
  s.description      = <<-DESC
                       AttributedString displayer view.
                       DESC

  s.homepage         = "https://github.com/winddpan/CSLabel"
  s.license          = 'MIT'
  s.author           = { "winddpan" => "winddpan@126.com" }
  s.source           = { :git => "https://github.com/winddpan/CSLabel.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'CSLabel/**/*'


  s.frameworks = 'UIKit', 'Foundation'
  s.library = 'xml2'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"${SDK_DIR}/usr/include/libxml2"' }
end
