(in-package :cl-user)

(defpackage :markov-gen (:use :cl))

(in-package :markov-gen)

(defun top (s)
  "文字列 s の最初の1文字からなる文字列を返す。"
  (subseq s 0 1))

(defun but-top (s)
  "文字列 s から最初の1文字を除いた文字列を返す。"
  (subseq s 1))

(defun cat (ss)
  "文字列のリストを引数に取り、それらを連結した文字列を返す。"
  (labels ((cat2 (a b)
             (concatenate 'string a b)))
    (if (null ss) ""
        (cat2 (car ss) (cat (cdr ss))))))

(defun n-gram (s &optional (n 2))
  "文字列 s を n-グラム化したリストを返す。文字列は句点（。）で終わること。"
  (labels ((dup (n str ret)
             (let ((bt (but-top str)))
               (if (= n 1) ret
                   (dup (- n 1) bt (cons bt ret)))))
           (n-gram-aux (m)
             (if (string= "" (car m)) nil
                 (cons (cat (mapcar #'top m))
                       (n-gram-aux (mapcar #'but-top m))))))
    (mapcar #'reverse (n-gram-aux (dup n s (list s))))))

(defvar *dic* "dic.lisp")

;;FIXME: fname が前もって存在しないとエラー
(defun append-to-file (sexp &optional (fname *dic*))
  (with-open-file (out fname
                       :direction :output
                       :if-exists :append)
    (print sexp out)))

(defun make-n-gram (&optional (n 2))
  "標準入力から文字列読んで、n-gram にし、ファイルにセーブ。デフォルトは 2-gram。
  文字列は句点（。）で終わること。"
  (loop for line = (read-line t nil) until (string= "" line)
     do (append-to-file (n-gram line n))))

(defun prep-text-file (infile outfile)
  "テキストファイルinfile を make-n-gram-from-file の処理に適した形式に変換する。
つまり、各行が句点（。）で終わるよう変形する。"
  (with-open-file (out outfile
                       :direction :output
                       :if-exists :supersede)
    (with-open-file (in infile)
      (loop for char = (read-char in nil) while char
         do (progn (write-char char out)
                   (if (char= char #\。) (write-char #\Newline out)))))))

;; FIXME: 終了条件が良くない。(string= "" line)では空行でループが終わってしまう。
(defun make-n-gram-from-file (infile &optional (n 2))
  "infile の各行は句点（。）で終了していること。"
  (with-open-file (in infile)
    (loop for line = (read-line in nil) until (string= "" line)
         do (append-to-file (n-gram line n)))))

(defvar *n-gram* nil)

(defun load-from-file (&optional (fname *dic*))
  "ファイルにセーブした n-gram を読み込む。"
  (setf *n-gram* nil)
  (with-open-file (in fname)
    (loop for line = (read in nil) while line
         do (setf *n-gram* (nconc *n-gram* line)))))

(defvar *end* "。")

(defun end? (word)
  (string= *end* (top (reverse word))))

(defun markov-gen (s)
  "スタート文字 s から出現頻度にもとづき文を生成。"
  (labels
      ((M (s ret)
         (let* ((words (remove-if-not #'(lambda (x) (string= s (top x))) *n-gram*))
                (word (if (null words) (nth (random (length *n-gram*)) *n-gram*)
                          (nth (random (length words)) words))))
           (cond
             ((end? word) (cons *end* (cons word ret)))
             (t (M (top (reverse  word)) (cons word ret)))))))
    (cat (reverse (mapcar #'top (M s nil))))))

;; sample usage
(prep-text-file "sample.txt" "infile.txt")
(make-n-gram-from-file "infile.txt")
(load-from-file)
(markov-gen "親")
(markov-gen "こ")
(markov-gen "な")
