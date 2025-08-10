(define test-null?
  (lambda ()
    (print "running test-null?...")
    (assert (null? '()) "expected '() to be considered null")
    (assert (not (null? #f)) "expected value to not be considered null")
    (assert (not (null? 123)) "expected value to not be considered null")
    (assert (not (null? "hi")) "expected value to not be considered null")
    (assert (not (null? '(1 . 2) "expected value to not be considered null")))))

(define test-pair?
  (lambda ()
    (print "running test-pair?...")
    (assert (pair? (cons 1 2)) "expected value to be considered a pair")
    (assert (pair? '(1)) "expected value to be considered a pair")
    (assert (pair? '(1 2 3)) "expected value to be considered a pair")
    (assert (not (pair? '())) "expected value to not be considered a pair")
    (assert (not (pair? #f)) "expected value to not be considered a pair")
    (assert (not (pair? "hi")) "expected value to not be considered a pair")
    (assert (not (pair? 123)) "expected value to not be considered a pair")))

(define test-list?
  (lambda ()
    (print "running test-list?...")
    (assert (list? '(1)) "expected value to be considered a list")
    (assert (list? '(1 2 3)) "expected value to be considered a list")
    (assert (list? '()) "expected value to be considered a list")
    (assert (not (list? (cons 1 2))) "expected value to not be considered a list")
    (assert (not (list? #f)) "expected value to not be considered a list")
    (assert (not (list? "hi")) "expected value to not be considered a list")
    (assert (not (list? 123)) "expected value to not be considered a list")))

(define test-symbol?
  (lambda ()
    (print "running test-symbol?...")
    (assert (symbol? 'x) "expected value to be considered a symbol")
    (assert (symbol? '+) "expected value to be considered a symbol")
    (assert (not (symbol? (cons 1 2))) "expected value to not be considered a symbol")
    (assert (not (symbol? #f)) "expected value to not be considered a symbol")
    (assert (not (symbol? "hi")) "expected value to not be considered a symbol")
    (assert (not (symbol? 123)) "expected value to not be considered a symbol")))

(define test-boolean?
  (lambda ()
    (print "running test-boolean?...")
    (assert (boolean? #t) "expected value to be considered a boolean")
    (assert (boolean? #f) "expected value to be considered a boolean")
    (assert (not (boolean? (cons 1 2))) "expected value to not be considered a boolean")
    (assert (not (boolean? '())) "expected value to not be considered a boolean")
    (assert (not (boolean? "hi")) "expected value to not be considered a boolean")
    (assert (not (boolean? 123)) "expected value to not be considered a boolean")))

(define test-number?
  (lambda ()
    (print "running test-number?...")
    (assert (number? 0) "expected value to be considered a number")
    (assert (number? 1) "expected value to be considered a number")
    (assert (number? 2.5) "expected value to be considered a number")
    (assert (not (number? (cons 1 2))) "expected value to not be considered a number")
    (assert (not (number? #f)) "expected value to not be considered a number")
    (assert (not (number? "hi")) "expected value to not be considered a number")))

(define test-string?
  (lambda ()
    (print "running test-string?...")
    (assert (string? "") "expected value to be considered a string")
    (assert (string? "hi") "expected value to be considered a string")
    (assert (not (string? (cons 1 2))) "expected value to not be considered a string")
    (assert (not (string? #f)) "expected value to not be considered a string")
    (assert (not (string? 123)) "expected value to not be considered a string")))

(define main
  (lambda ()
    (print "starting scm/t.scm tests")
    (test!)))

(main)
