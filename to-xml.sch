(library (to-xml)
  (export to-xml xml-file)
  (import (rnrs))

  (define (to-xml expr)
    (call/cc (lambda (err-break)
              (define (iter:list->attrs&contents lst attr-stack content-stack)
                (define (handle-xml-content e)
                  (iter:list->attrs&contents
                    (cdr lst)
                    attr-stack
                    (cons (cond
                            [(string? e) e]
                            [(list? e)   (to-xml e)]
                            [else        (err-break 'err)])
                     content-stack)))
                (if (null? lst)
                  (values
                    (apply string-append (reverse attr-stack))
                    (apply string-append (reverse content-stack)))
                  (let ([e (car lst)])
                    (if (symbol? e)
                      (let ([e-str (symbol->string e)])
                        (if (and
                              (> (string-length e-str) 1)
                              (char=? (string-ref e-str 0) #\:))
                          (iter:list->attrs&contents
                            (cddr lst)
                            (append
                              `("\" "
                                ,(let ([attr (cadr lst)])
                                  (cond [(string? attr) attr]
                                        [else           (err-break 'err)]))
                                "=\""
                                ,(substring
                                  (symbol->string e)
                                  1
                                  (string-length (symbol->string e))))
                              attr-stack)
                            content-stack)
                          (handle-xml-content e)))
                      (handle-xml-content e)))))
              (cond [(symbol? expr) (symbol->string expr)]
                    [(number? expr) (number->string expr)]
                    [(list? expr)
                     (apply string-append
                       (let-values ([(attrs contents) (iter:list->attrs&contents (cdr expr) '() '())])
                         (if (symbol? (car expr))
                           (let ([tag-name (symbol->string (car expr))])
                             `("<" ,tag-name " " ,attrs ">" ,contents "<" ,tag-name "/>"))
                           (err-break 'err))))]))))

  (define (xml-file path prelude expr)
    (let ([xml (to-xml expr)])
      (if (file-exists? path)
        (delete-file path))
      (unless (and (symbol? xml) (symbol=? xml 'err))
        (with-output-to-file path
          (lambda ()
            (display prelude)
            (display xml)))
        'err))))
