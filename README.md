# scheme-to-xml
LISP list to xml on 60lines

e.g.
```scheme
(import (to-xml))
(xml-file "output.xml"
  '(xml-tag :attr "attr1" (tag2 "2") "3"))
```
`output.xml`:
```xml
<xml-tag attr="attr1" ><tag2 >2<tag2/>3<xml-tag/>
```
invalid syntax -> `xml-file` return `'err`.
