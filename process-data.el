;; -*- lexical-binding: t; -*-

(require 'json)
(require 'cl-lib)
(require 'dash)

(defun k/process-title (title)
  "Process TITLE to replace problematic characters, and so on."
  ;; Mainly to normalize to half-width characters.
  (thread-last
    title
    ucs-normalize-NFKC-string
    (replace-regexp-in-string "'" "’")
    (replace-regexp-in-string (rx "?") (rx "？"))))

(defun k/extract-development-version (word file output-path)
  "Read FILE and write its definition of WORD to OUTPUT-PATH.

The structure in FILE is preserved in OUTPUT-PATH.

This allows for not having to load everything when I'm only
iterating on one page.

Does nothing if OUTPUT-PATH already exists as a file."
  (declare (indent 1))
  (unless (file-exists-p output-path)
    (let (parsed)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (setq parsed (json-parse-buffer :array-type 'list)))
      (with-temp-file output-path
        (insert
         (let ((json-encoding-pretty-print t))
           (json-encode
            (--filter (equal word (gethash "title" it))
                      parsed))))))))

(unless noninteractive
  (k/extract-development-version "挨"
    "dicts/ministry-of-education/dict_revised.json" "dev-dict_revised.json")
  (k/extract-development-version "挨"
    "dicts/moedict-data-twblg/dict-twblg.json" "dev-dict-twblg.json")
  (k/extract-development-version "挨"
    "dicts/ministry-of-education/dict_concised.json" "dev-dict_concised.json")
  (k/extract-development-version "一枕南柯"
    "dicts/ministry-of-education/dict_idioms.json" "dev-dict_idioms.json"))

(defun main ()
  (let* ((all-titles (list))
         (merged-result (make-hash-table :test #'equal))
         (dictionaries
          (if (and (or (not noninteractive)
                       (getenv "DEV"))
                   (file-exists-p "dev-dict_revised.json")
                   (file-exists-p "dev-dict-twblg.json")
                   (file-exists-p "dev-dict_concised.json")
                   (file-exists-p "dev-dict_idioms.json"))
              [("moedict_twblg" . "dev-dict-twblg.json")
               ("dict_revised" . "dev-dict_revised.json")
               ("dict_concised" . "dev-dict_concised.json")
               ("dict_idioms" . "dev-dict_idioms.json")
               ("kisaragi_dict" . "dicts/kisaragi/kisaragi_dict.json")]
            [("moedict_twblg" . ("dicts/moedict-data-twblg/dict-twblg.json"
                                 "dicts/moedict-data-twblg/dict-twblg-ext.json"))
             ("dict_revised" . "dicts/ministry-of-education/dict_revised.json")
             ("dict_concised" . "dicts/ministry-of-education/dict_concised.json")
             ("dict_idioms" . "dicts/ministry-of-education/dict_idioms.json")
             ("kisaragi_dict" . "dicts/kisaragi/kisaragi_dict.json")]))
         (dict-count (length dictionaries))
         ;; A list of the original parsed dictionary data
         (raw-dicts (make-vector dict-count nil))
         (shaped-dicts (make-vector dict-count nil)))
    (dotimes (i dict-count)
      (with-temp-buffer
        (message "Parsing %s (%s/%s)..."
                 (car (aref dictionaries i))
                 (1+ i) dict-count)
        (let ((files (cdr (aref dictionaries i))))
          (when (stringp files)
            (setq files (list files)))
          (->> (cl-loop for f in files
                        nconc
                        (progn
                          (erase-buffer)
                          (insert-file-contents f)
                          (json-parse-buffer :array-type 'list)))
               (aset raw-dicts i)))))
    ;; [{:title "title"
    ;;   :heteronyms (...)
    ;;   ... ...}
    ;;  ...]
    ;; -> {"title" {heteronyms (...)}
    ;;     ...}
    ;;
    ;; For entries without heteronyms:
    ;; [{:title "title"
    ;;   :definition "def"
    ;;   ... ...}
    ;;  ...]
    ;; -> {"title" {heteronyms [{definition "def" ...}]}
    ;;     ...}
    (dotimes (i dict-count)
      (message "Shaping data for %s (%s/%s)..."
               (car (aref dictionaries i))
               (1+ i) dict-count)
      (let ((shaped (make-hash-table :test #'equal)))
        (dolist (entry (aref raw-dicts i))
          (let* ((title (k/process-title (gethash "title" entry)))
                 ;; If the dictionary does not declare heteronyms in a
                 ;; key, we set the heteronyms to a list with the
                 ;; entry itself.
                 (heteronyms (or (gethash "heteronyms" entry)
                                 (list entry)))
                 (tmp (make-hash-table :test #'equal)))
            ;; If an entry with the title already exists, insert into
            ;; its heteronyms.
            (when-let (existing (gethash title shaped))
              (setq heteronyms
                    (append (gethash "heteronyms" existing)
                            heteronyms)))
            ;; Sort the heteronyms according to the het_sort key.
            (when (and
                   ;; Skip checking the rest if the first already
                   ;; doesn't have it.
                   (gethash "het_sort" (car heteronyms))
                   (--all? (gethash "het_sort" it)
                           (cdr heteronyms)))
              (setq heteronyms
                    (--sort
                     (< (string-to-number
                         (gethash "het_sort" it))
                        (string-to-number
                         (gethash "het_sort" other)))
                     heteronyms)))
            (puthash "heteronyms" heteronyms tmp)
            (puthash title tmp shaped)))
        (aset shaped-dicts i shaped)))
    (dotimes (i dict-count)
      (message "Collecting titles (%s/%s)..." (1+ i) dict-count)
      (cl-loop
       for k being the hash-keys of (aref shaped-dicts i)
       do (push k all-titles)))
    (message "Removing duplicate titles...")
    (setq all-titles (-uniq all-titles))
    (message "Merging...")
    (dolist (title all-titles)
      (let ((hash-table (make-hash-table :test #'equal)))
        (puthash "title" title hash-table)
        (dotimes (i dict-count)
          (when-let (v (gethash title (aref shaped-dicts i)))
            (puthash (car (aref dictionaries i)) v
                     hash-table)))
        (puthash title hash-table merged-result)))
    (message "Writing result out to disk...")
    (make-directory "src/_data" t)
    (with-temp-file "src/titles.json"
      (let ((json-encoding-pretty-print (not noninteractive)))
        (insert (json-encode all-titles))))
    (with-temp-file "src/_data/combined.json"
      (let ((json-encoding-pretty-print (not noninteractive)))
        (insert (json-encode merged-result))))
    (message "Done")))

(if (and (fboundp #'native-comp-available-p)
         (native-comp-available-p))
    (native-compile #'main)
  (byte-compile #'main))
(main)
(when noninteractive
  (kill-emacs))

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; End:
