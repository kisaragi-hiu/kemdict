;; -*- lexical-binding: t; -*-

(require 'ht)

(defvar k/tmp1 (make-hash-table))
(defvar k/tmp2 (make-hash-table))
(defvar k/merged-result (list))
(defvar k/all-titles (list))

(let ((moedict-zh (with-temp-buffer
                    (insert-file-contents "moedict-data/dict-revised.json")
                    (goto-char (point-min))
                    (json-parse-buffer :array-type 'list)))
      (moedict-twblg (with-temp-buffer
                       (insert-file-contents "moedict-data-twblg/dict-twblg.json")
                       (goto-char (point-min))
                       (json-parse-buffer :array-type 'list))))
  (message "%s" "Finished parsing")
  (dolist (entry moedict-zh)
    (push (gethash "title" entry) k/all-titles))
  (dolist (entry moedict-twblg)
    (push (gethash "title" entry) k/all-titles))
  (setq k/all-titles (-uniq k/all-titles))
  (message "%s" "Finished collecting all titles")
  (dolist (entry moedict-zh)
    (let ((title (gethash "title" entry)))
      (puthash title
               (ht
                ("title" title)
                ("moedict_zh" (ht ("heteronyms" (gethash "heteronyms" entry)))))
               k/tmp1)))
  (message "%s" "Finished reforming dictionary (1/2)")
  (dolist (entry moedict-twblg)
    (let ((title (gethash "title" entry)))
      (puthash title
               (ht
                ("title" title)
                ("moedict_twblg" (ht ("heteronyms" (gethash "heteronyms" entry)))))
               k/tmp2)))
  (message "%s" "Finished reforming dictionary (2/2)")
  (dolist (title k/all-titles)
    (let ((hash-table (ht ("title" title))))
      (when-let (v (gethash title k/tmp1))
        (puthash "moedict_zh" v hash-table))
      (when-let (v (gethash title k/tmp2))
        (puthash "moedict_twblg" v hash-table))
      (push hash-table k/merged-result)))
  (message "%s" "Finished merging")
  (make-directory "src/_data" t)
  (with-temp-file "src/_data/combined.json"
    (insert (json-encode k/merged-result)))
  (message "%s" "Done"))

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; End: