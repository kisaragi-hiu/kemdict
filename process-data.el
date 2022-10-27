;; -*- lexical-binding: t; -*-

(require 'json)
(require 'cl-lib)
(require 'dash)

(defun main ()
  (let ((moedict-zh-shaped (make-hash-table :test #'equal))
        (moedict-twblg-shaped (make-hash-table :test #'equal))
        (all-titles (list))
        (merged-result (list))
        (moedict-zh (with-temp-buffer
                      (message "%s" "Parsing (1/2)...")
                      (insert-file-contents "moedict-data/dict-revised.json")
                      (goto-char (point-min))
                      (json-parse-buffer :array-type 'list)))
        (moedict-twblg (with-temp-buffer
                         (message "%s" "Parsing (2/2)...")
                         (insert-file-contents "moedict-data-twblg/dict-twblg.json")
                         (goto-char (point-min))
                         (json-parse-buffer :array-type 'list))))
    (message "%s" "Collecting titles...")
    (dolist (entry moedict-zh)
      (push (gethash "title" entry) all-titles))
    (dolist (entry moedict-twblg)
      (push (gethash "title" entry) all-titles))
    (message "%s" "Removing duplicate titles...")
    (setq all-titles (-uniq all-titles))
    (message "%s" "Shaping dictionary data (1/2)...")
    (dolist (entry moedict-zh)
      (let ((title (gethash "title" entry)))
        (let ((tmp (make-hash-table :test #'equal)))
          (puthash "heteronyms" (gethash "heteronyms" entry) tmp)
          (puthash title tmp moedict-zh-shaped))))
    (message "%s" "Shaping dictionary data (2/2)...")
    (dolist (entry moedict-twblg)
      (let ((title (gethash "title" entry)))
        (let ((tmp (make-hash-table :test #'equal)))
          (puthash "heteronyms" (gethash "heteronyms" entry) tmp)
          (puthash title tmp moedict-twblg-shaped))))
    (message "%s" "Merging...")
    (dolist (title all-titles)
      (let ((hash-table (make-hash-table :test #'equal)))
        (puthash "title" title hash-table)
        (when-let (v (gethash title moedict-zh-shaped))
          (puthash "moedict_zh" v hash-table))
        (when-let (v (gethash title moedict-twblg-shaped))
          (puthash "moedict_twblg" v hash-table))
        (push hash-table merged-result)))
    (message "%s" "Writing result out to disk...")
    (make-directory "src/_data" t)
    (with-temp-file "src/_data/combined.json"
      (let ((json-encoding-pretty-print (not noninteractive)))
        (insert (json-encode merged-result))))
    (message "%s" "Done")))

(if (featurep 'comp)
    (native-compile #'main)
  (byte-compile #'main))
(main)
(when noninteractive
  (kill-emacs))

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; End:
