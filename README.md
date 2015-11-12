# CSLabel
HTML -> TextKit

# Usage
```
NSString *html = @"<p><img src=\"https://www.baidu.com/img/bdlogo.png\"></p>"
"<p><a href=\"http://www.baidu.com\">baidu</a></p>"
"<p>the last paragraph!</p>";

CSHTMLTextAttachmentSerializerName *attachmentSerializer = [CSHTMLTextAttachmentSerializerName new];
attachmentSerializer.placeholderImage = ...;
attachmentSerializer.failedImage = ...;

CSLabel *label = ...
label.delegate = self;
[label setHTML:html withAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17],
NSForegroundColorAttributeName : [UIColor grayColor],
CSHTMLTextAttachmentSerializerName : attachmentSerializer}];
```
# Support html
* strong / b
* em / i
* strike
* u
* sub
* sup
* ul ol li
* img
* table

# Attributes usage
* You can use CSHTMLTextAttachmentSerializerName class to set downloading/failed image placeholder
* Support all CoreText attribute such like NSFontAttributeName, NSForegroundColorAttributeName and so on

## Author

winddpan, winddpan@126.com

## License

CSLabel is available under the MIT license. See the LICENSE file for more info.
