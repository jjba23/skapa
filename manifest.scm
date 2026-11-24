;; skapa
;;
;; SPDX-License-Identifier: MIT
;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

(use-modules (guix packages)
             (gnu)
             (gnu packages)
             (guix utils)
             (guix git-download)
             (guix download)
             (gnu packages guile)
             (gnu packages nss)
             (gnu packages admin)
             (gnu packages web)
             (gnu packages gnupg)
             (gnu packages guile-xyz)
             (gnu packages pkg-config)
             (guix build-system guile)
             (gnu packages linux)
             (gnu packages compression)
             (gnu packages texinfo)
             (gnu packages autotools)
             (gnu packages rust-apps)
             ;; The channel pinned in channels.scm carries the release the
             ;; collection is built against; the prefix keeps it apart from the
             ;; older copies Guix itself carries.
             ((jointhefreeworld packages guile)
              #:prefix jtf:)
             ((guix licenses)
              #:prefix license:))

(packages->manifest (list guile-3.0
                          (specification->package "texinfo")
                          watchexec
                          jtf:guile-scriba
                          (specification->package "guile-dokgen")
                          guile-ares-rs))
