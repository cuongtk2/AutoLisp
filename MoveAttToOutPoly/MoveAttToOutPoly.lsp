(defun c:MoveAttToOutPoly (/ ss-poly ss-blocks poly-ent poly-data verts n-verts
                              bi br-ent pos pos2d vtx-idx out-dir
                              att-ent att-data att-height new-pos offset ok)

  ;; Lay danh sach toa do 2D cac vertex tu entget (group 10)
  (defun _get-verts (ent-data / result pair)
    (setq result nil)
    (foreach pair ent-data
      (if (= (car pair) 10)
        (setq result (append result (list (list (cadr pair) (caddr pair)))))
      )
    )
    result
  )

  ;; Normalize vector 2d
  (defun _norm2d (v / len)
    (setq len (sqrt (+ (* (car v) (car v)) (* (cadr v) (cadr v)))))
    (if (> len 1e-9)
      (list (/ (car v) len) (/ (cadr v) len))
      (list 0.0 1.0)
    )
  )

  ;; Tim index vertex gan pt nhat trong tolerance, tra ve -1 neu khong tim thay
  (defun _find-vertex (verts pt tol / nv k vpt result)
    (setq nv     (length verts)
          k      0
          result -1)
    (while (and (< k nv) (= result -1))
      (setq vpt (nth k verts))
      (if (< (distance pt vpt) tol)
        (setq result k)
      )
      (setq k (1+ k))
    )
    result
  )

  ;; Ray-casting: kiem tra pt (list x y) co nam trong poly khong
  (defun _inside-poly (verts pt / nv k j ak aj inside)
    (setq nv     (length verts)
          k      0
          j      (1- nv)
          inside nil)
    (while (< k nv)
      (setq ak (nth k verts)
            aj (nth j verts))
      (if (and (/= (> (cadr ak) (cadr pt))
                   (> (cadr aj) (cadr pt)))
               (< (car pt)
                  (+ (* (/ (- (car aj) (car ak))
                            (- (cadr aj) (cadr ak)))
                         (- (cadr pt) (cadr ak)))
                     (car ak))))
        (setq inside (not inside))
      )
      (setq j k
            k (1+ k))
    )
    inside
  )

  ;; Bisector huong ra ngoai tai vertex idx
  (defun _outward-bisector (verts idx / nv v vp vn u1 u2 bis seg test-pt)
    (setq nv (length verts)
          v  (nth idx verts)
          vp (nth (rem (+ idx (1- nv)) nv) verts)
          vn (nth (rem (1+ idx) nv) verts))
    (setq u1 (_norm2d (list (- (car vp) (car v)) (- (cadr vp) (cadr v))))
          u2 (_norm2d (list (- (car vn) (car v)) (- (cadr vn) (cadr v)))))
    (setq bis (list (+ (car u1) (car u2))
                    (+ (cadr u1) (cadr u2))))
    ;; Goc 180 do: bisector xap xi zero -> dung phap tuyen segment
    (if (< (sqrt (+ (* (car bis) (car bis))
                    (* (cadr bis) (cadr bis)))) 1e-9)
      (progn
        (setq seg (_norm2d (list (- (car vn) (car vp))
                                 (- (cadr vn) (cadr vp)))))
        (setq bis (list (- (cadr seg)) (car seg)))
      )
    )
    (setq bis (_norm2d bis))
    ;; Neu test-pt nam trong poly thi dang huong vao trong -> negate
    (setq test-pt (list (+ (car v)  (* (car bis)  0.01))
                        (+ (cadr v) (* (cadr bis) 0.01))))
    (if (_inside-poly verts test-pt)
      (setq bis (list (- (car bis)) (- (cadr bis))))
    )
    bis
  )

  ;; Set hoac them group code vao entdata
  (defun _set-code (ent-data code val / pair)
    (setq pair (assoc code ent-data))
    (if pair
      (subst (cons code val) pair ent-data)
      (append ent-data (list (cons code val)))
    )
  )

  ;;==========================================================
  ;; MAIN
  ;;==========================================================
  (setq ok t)

  ;; 1. Chon polyline
  (setq poly-ent  (car (entsel "\nPick closed polyline"))
      poly-obj  (vlax-ename->vla-object poly-ent)
      poly-data (entget poly-ent)
      verts     (_get-verts poly-data)
      n-verts   (fix (vlax-curve-getEndParam poly-obj)))

  ;; 2. Chon cac block moc goc ranh
  (if ok
    (progn
      (princ "\nChon cac block moc goc ranh: ")
      (setq ss-blocks (ssget '((0 . "INSERT"))))
      (if (null ss-blocks)
        (progn (princ "\nKhong co block nao duoc chon.") (setq ok nil))
      )
    )
  )

  ;; 3. Xu ly tung block
  (if ok
    (progn
      (setq bi 0)
      (while (< bi (sslength ss-blocks))
        (setq br-ent (ssname ss-blocks bi)
              pos    (cdr (assoc 10 (entget br-ent)))
              pos2d  (list (car pos) (cadr pos)))

        (setq vtx-idx (_find-vertex verts pos2d 1e-3))

        (if (< vtx-idx 0)
          (princ (strcat "\nBlock tai ("
                         (rtos (car pos2d) 2 3) ", "
                         (rtos (cadr pos2d) 2 3)
                         ") khong nam tren vertex nao, bo qua."))
          (progn
            (setq out-dir (_outward-bisector verts vtx-idx))

            (setq att-ent (entnext br-ent))
            (while (and att-ent
                        (= (cdr (assoc 0 (entget att-ent))) "ATTRIB"))
              (setq att-data   (entget att-ent)
                    att-height (cdr (assoc 40 att-data))
                    offset     (* 1.5 att-height)
                    new-pos    (list (+ (car  pos) (* (car  out-dir) offset))
                                     (+ (cadr pos) (* (cadr out-dir) offset))
                                     (caddr pos)))

              ;; Doi sang Middle Center justify
              (setq att-data (_set-code att-data 72 1)) ; horizontal: center
              (setq att-data (_set-code att-data 74 2)) ; vertical:   middle
              ;; Group 11 la alignment point khi justify != left
              (setq att-data (_set-code att-data 11 new-pos))

              (entmod att-data)
              (entupd att-ent)
              (setq att-ent (entnext att-ent))
            )
          )
        )
        (setq bi (1+ bi))
      )
      (princ "\nHoan thanh.")
    )
  )
  (princ)
)
