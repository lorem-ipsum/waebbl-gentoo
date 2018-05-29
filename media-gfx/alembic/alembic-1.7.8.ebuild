# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 )

inherit eutils python-single-r1 cmake-utils

DESCRIPTION="Alembic is an open framework for storing and sharing scene data"
HOMEPAGE="http://alembic.io/"
SRC_URI="https://github.com/${PN}/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Alembic"

SLOT="0"

# The only arch I do have access to
KEYWORDS="~amd64"

IUSE="+boost doc hdf5 pyalembic test +zlib"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	hdf5? ( zlib )
	pyalembic? ( boost )"

DEPEND="${PYTHON_DEP}
	>=dev-util/cmake-3.9.6
	boost? ( >=dev-libs/boost-1.65.0 )
	doc? ( >=app-doc/doxygen-1.8.13-r1 )
	pyalembic? ( >=dev-python/pyilmbase-2.2.1 )"

RDEPEND="${PYTHON_DEP}
	>=media-libs/openexr-2.2.1
	hdf5? ( >=sci-libs/hdf5-1.8.18[zlib(+)] )
	zlib? ( >=sys-libs/zlib-1.2.11-r1 )"

DOCS=( "ACKNOWLEDGEMENTS.txt" "FEEDBACK.txt" "NEWS.txt" "README.txt" )
#HTML_DOCS=( "doc/html" )
PATCHES=( "${FILESDIR}/${PN}-FindIlmBase-pkgconfig.patch"
	"${FILESDIR}/${P}-CMakeLists-fix_lib.patch" )

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	cmake-utils_src_prepare
}

# Static linking, the use of tr1 and support for prman might be added
# in the future.
src_configure() {
	# I don't have a license for arnold renderer or maya so I disable them
	# as default.
	# Also I'm currently not using renderman, so I disable the prman flag
	# by default too.
	local mycmakeargs=(
		-DUSE_ARNOLD=OFF
		-DUSE_BINARIES=ON
		-DUSE_EXAMPLES=OFF
		-DUSE_HDF5=$(usex hdf5)
		-DUSE_MAYA=OFF
		-DUSE_PRMAN=OFF
		-DUSE_PYALEMBIC=$(usex pyalembic)
		-DUSE_STATIC_BOOST=OFF	# I won't use static libraries
		-DUSE_STATIC_HDF5=OFF
		-DUSE_TESTS=$(usex test)
		-DALEMBIC_ILMBASE_LINK_STATIC=OFF # I don't want to link statically against ilmbase
		-DALEMBIC_SHARED_LIBS=ON # For now let's ignore building static libraries
		-DALEMBIC_LIB_USES_BOOST=$(usex boost)
		-DALEMBIC_LIB_USES_TR1=$(usex !boost)
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use doc; then
		doxygen -u Doxyfile
		doxygen Doxyfile
	fi
}

src_test() {
	if use test; then
		cmake-utils_src_test
	fi
}

src_install() {
	DESTDIR="${D}" cmake-utils_src_install
	if use doc; then
		dodoc -r "doc/html"
	fi

	# move the cmake files from lib->lib64
	mv "${D}/usr/lib/cmake" "${D}/usr/lib64/cmake" && rmdir "${D}/usr/lib"
}
