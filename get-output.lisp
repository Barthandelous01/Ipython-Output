(defun concat-strings (list)
  "A non-recursive function that concatenates a list of strings.

Credit to http://stackoverflow.com/questions/5457346/ddg#5457447"
  (if (listp list)
      (let ((result ""))
	(dolist (item list)
          (if (stringp item)
              (setq result (concatenate 'string result item))))
	result)))

(defun read-json (input)
  "Read the json input of a file given a string or a pathname.

Returns a list representing the json."
  (with-open-file (file input)
		  (json:decode-json file)))

(defun get-code-cells (json)
  "Return a list of just the code cells in an ipython notebook."
  (loop for x in (cdr (first json))
	for y = 1 then y when (string= (cdr (first x)) "code")
	collecting x))

(defun get-output (code-cell)
  "Get the correct output list from a cell of code."
  (fourth code-cell))

(defun text-from-outputs (output)
  "Get the stdin and stdout from an output cell."
  (if (not (eq nil (cdr output)))
      (let ((result '()))
	(loop for x in (cdr output)
	      when (and
		    (stringp (cdr (first x)))
		    (or
		     (string= (cdr (first x)) "stdin")
		     (string= (cdr (first x)) "stdout")))
	      do (push (concat-strings (cdr (third x))) result))
	result)))

(defun flatten-null (list)
  "Remove the nulls from a list"
  (loop for x in list when (not (eq nil x)) collecting x))

(defun flip-stdin-stdout (output-list)
  "Take a list of the form '(output input) and return one
with those values flipped."
  (let ((result '()))
    (loop for x in output-list do
	  (if (eq nil (cdr x))
	      (push x result)
	    (push (reverse x) result)))
    result))

(defun enumerate (list)
  "return a list of conses, for each thing in the list with a number."
  (loop for x in list
	for y = 1 then (+ 1 y)
	collecting (cons y x)))

(defun prepare-output-list (local-file)
  "Given a local filename, build up a massive pipeline of list transformations
that give us a useable list of numbered outputs."
  (enumerate
   (reverse
    (map 'list #'concat-strings
	 (flip-stdin-stdout
	  (flatten-null
	   (map 'list #'text-from-outputs
		(map 'list #'get-output
		     (get-code-cells (read-json local-file))))))))))

(defun do-nice-output (filename list)
  "Neatly print an enumerated list of output."
  (with-open-file (output filename :direction :output)
		  (loop for (num . val) in list do
			(format output
				"*Problem Number ~a*~%~%#+BEGIN_SRC~%~a#+END_SRC~%~%"
				num val))))

(defun main (filename)
  "Run the actual thing given a filename."
  (let* ((infile (pathname filename))
	 (outfile (pathname
		   (concatenate 'string
				(pathname-name infile)
				".org")))
	 (json (prepare-output-list infile)))
    (do-nice-output outfile json)))
