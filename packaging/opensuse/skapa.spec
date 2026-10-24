#
# spec file for package skapa
#
# Copyright (c) 2026 SUSE LLC and contributors
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# Scheme sources plus a bash launcher: there is no compiled binary to
# debug, so the empty -debugsource package is skipped.
%global debug_package %{nil}

Name:           skapa
Version:        0.0.6
Release:        0
Summary:        Project scaffolding and templating wizard in Guile Scheme
License:        GPL-3.0-or-later
URL:            https://codeberg.org/jjba23/skapa
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  pkgconfig(guile-3.0)
BuildRequires:  scriba
Requires:       guile
Requires:       bash
Requires:       coreutils
Requires:       scriba

# scriba is produced by the same packaging batch; build it first.

%description
Skapa scaffolds a new project from a template. Templates are written as
S-expressions and filled in interactively; the package ships templates for
Guile projects and the licenses they need, and more can be added.

%prep
%autosetup -n %{name}-%{version}

# The launcher is a bash script; point it at the interpreter path
# openSUSE packages are expected to use instead of /usr/bin/env.
sed -i '1s|^#!%{_bindir}/env \(.*\)$|#!%{_bindir}/\1|' scripts/skapa

%build
# Nothing to build: the program is Scheme sources plus a launcher, and
# the sources are byte-compiled during %install so that they land in
# the interpreter's compiled-module directory.

%install
# Both directories are asked of Guile's pkg-config file rather than
# assumed, so the modules land where this distribution's Guile looks
# for them.
SITE_DIR="%{buildroot}$(pkg-config --variable=sitedir guile-3.0)"
CCACHE_DIR="%{buildroot}$(pkg-config --variable=siteccachedir guile-3.0)"

mkdir -p "$SITE_DIR/skapa" "$CCACHE_DIR/skapa"
cp -r src/skapa/. "$SITE_DIR/skapa/"

# Byte-compile every module so that loading it does not compile it
# again on first use.
find "$SITE_DIR/skapa" -name '*.scm' | while read -r scm_file; do
  rel_path="${scm_file#$SITE_DIR/}"
  go_file="$CCACHE_DIR/${rel_path%.scm}.go"
  mkdir -p "$(dirname "$go_file")"
  guild compile -L "$SITE_DIR" -o "$go_file" "$scm_file"
done

install -D -m 0755 scripts/skapa %{buildroot}%{_bindir}/skapa

# Upstream reads resources from the generic share/resources; several of
# these packages would clash there, so it moves under share/skapa/.
sed -i 's|share/resources|share/skapa/resources|g' %{buildroot}%{_bindir}/skapa

install -d "%{buildroot}%{_datadir}/skapa/resources"
cp -r resources/. "%{buildroot}%{_datadir}/skapa/resources/"

%files
%license COPYING
%doc README.org
%{_bindir}/skapa
%dir %{_datadir}/guile
%dir %{_datadir}/guile/site
%dir %{_datadir}/guile/site/3.0
%{_datadir}/guile/site/3.0/skapa
%dir %{_libdir}/guile
%dir %{_libdir}/guile/3.0
%dir %{_libdir}/guile/3.0/site-ccache
%{_libdir}/guile/3.0/site-ccache/skapa
%dir %{_datadir}/skapa
%{_datadir}/skapa/resources

%changelog
