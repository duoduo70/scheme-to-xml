(library (to-xml)
  (export to-xml xml-file)
  (import (rnrs))

  (define (to-xml expr)
    (call/cc (lambda (err-break)
              (cond [(symbol? expr) (symbol->string expr)]
                    [(number? expr) (number->string expr)]
                    [(list? expr)
                     (apply string-append
                      (letrec ([f (lambda (lst attr-stack content-stack)
                                    (if (null? lst)
                                     (values
                                      (apply string-append (reverse attr-stack))
                                      (apply string-append (reverse content-stack)))
                                     (let ([e (car lst)])
                                      (cond
                                          [(and
                                            (symbol? e)
                                            (> (string-length (symbol->string e)) 1)
                                            (char=? (string-ref (symbol->string e) 0) #\:))
                                           (f
                                            (cdr (cdr lst))
                                            (append
                                             `(
                                               "\" "
                                               ,(let ([attr (car (cdr lst))])
                                                  (cond [(string? attr)
                                                         attr]
                                                      [else (err-break 'err)]))
                                               "=\""
                                               ,(substring
                                                  (symbol->string e)
                                                  1
                                                  (string-length (symbol->string e))))
                                             attr-stack)
                                            content-stack)]
                                          [else (f
                                                  (cdr lst)
                                                  attr-stack
                                                  (cons (cond
                                                          [(string? e) e]
                                                          [(list? e) (to-xml e)]
                                                          [else (err-break 'err)])
                                                   content-stack))]))))])
                       (call-with-values
                         (lambda () (f (cdr expr) '() '()))
                         (lambda (attrs contents)
                           (if (symbol? (car expr))
                             (let ([tag-name (symbol->string (car expr))])
                              `("<" ,tag-name " " ,attrs ">" ,contents "<" ,tag-name "/>"))
                             (err-break 'err))))))]))))

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
