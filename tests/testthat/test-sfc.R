test_that("we can print sfc objects", {
  pt1 = st_point(1:2)
  pt2 = st_point(3:4)
  s1 = st_sf(a = c("x", "y"), geom = st_sfc(pt1, pt2))
  expect_output(print(s1), "Simple feature collection")
  expect_output(print(st_sfc()), "Geometry set for 0 features")
  expect_length(st_sfc(), 0)
})

test_that("st_is_longlat works", {
  pt1 = st_point(1:2)
  pt2 = st_point(3:4)
  s1 = st_sf(a = c("x", "y"), geom = st_sfc(pt1, pt2))
  expect_equal(st_is_longlat(s1), NA)
  s2 = s1
  st_crs(s2) = 3857
  expect_false(st_is_longlat(s2))
  st_crs(s1) = 4326
  expect_true(st_is_longlat(s1))
})

test_that("st_crs returns NA for sfg objects", {
  pt1 = st_point(1:2)
  expect_true(is.na(st_crs(pt1)))
})

test_that("st_as_binary handles non-native big endian", {
  gc = st_geometrycollection()
  r = st_as_binary(gc)
  r[1] = if (r[1] == 1) {
  	as.raw(0)
  } else {
  	as.raw(1)
  }
  r[2:5] = rev(r[2:5]) # swap bytes
  expect_identical(gc, st_as_sfc(structure(list(r), class = "WKB"), pureR = TRUE)[[1]])
  expect_identical(gc, st_as_sfc(structure(list(r), class = "WKB"), pureR = TRUE, EWKB = TRUE)[[1]])
})

test_that("st_crs<- gives warnings on changing crs", {
	x = st_sfc(list(st_point(0:1), st_point(0:1)))
	y = x
	expect_silent(st_crs(y) <- 4326)
	expect_silent(st_crs(y) <- 4326)
	expect_warning(st_crs(y) <- 3857)
	x = st_sfc(list(st_point(0:1), st_point(0:1)), crs = 4326)
	#expect_silent(st_sfc(x, crs = "+proj=longlat +datum=WGS84 +no_defs"))
	#expect_silent(st_sfc(x, crs = "+proj=longlat +datum=WGS84")) #-->> breaks build on CRAN flavor fedora-gcc
	# but do when it changes:
	expect_warning(st_sfc(x, crs = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs"))
})

test_that("st_precision()", {
    x <- st_sfc(st_point(c(pi, pi)), precision = 1e-4, crs = 3857) # units m
    expect_equal(st_precision(x), 1e-4)
    expect_error(st_set_precision(x, NULL))
    expect_error(st_set_precision(x, NA), "numeric")
    expect_error(st_set_precision(x, list()), "length")
    expect_error(st_set_precision(x, list(x = 1)), "numeric")
    expect_error(st_set_precision(x, 1:4), "length")
    expect_error(st_set_precision(x, NA_real_), "numeric")
    st_precision(x) <- 1e-2
    expect_identical(st_set_precision(x, 1e-2), x)

	expect_identical(x, st_set_precision(x, units::set_units(100, m)))
	expect_error(st_set_precision(x, units::set_units(100, kg)))
	x <- st_transform(x, 4326)
	expect_silent(st_set_precision(x, units::set_units(0.001, rad)))
	expect_silent(st_set_precision(x, units::set_units(0.1, degree)))
	expect_error(st_set_precision(x, units::set_units(0.001, degree_C)))
})

test_that("st_precision() works for sf", {
    x <- st_as_sf(data.frame("a" = 1), 
                  st_sfc(st_point(c(pi, pi)), precision = 1e-4))
    expect_equal(st_precision(x), 1e-4)
    expect_error(st_set_precision(x, NULL))
    expect_error(st_set_precision(x, NA), "numeric")
    expect_error(st_set_precision(x, list()), "length")
    expect_error(st_set_precision(x, list(x = 1)), "numeric")
    expect_error(st_set_precision(x, 1:4), "length")
    expect_error(st_set_precision(x, NA_real_), "numeric")
    st_precision(x) <- 1e-2
    expect_identical(st_set_precision(x, 1e-2), x)
})

test_that("st_as_sfc breaks on wrong input", {
  expect_error(st_as_sfc("foo"))
})

test_that("st_coordinates works", {
    x <- st_sfc(st_point(c(pi, pi)), precision = 1e-4)
	expect_true(is.matrix(st_coordinates(st_sf(a = 1, geom = x))))
	expect_true(is.matrix(st_coordinates(x)))
	expect_true(is.matrix(st_coordinates(x[[1]])))
	nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
	expect_true(is.matrix(st_coordinates(nc)))
	# expect_true(is.matrix(st_coordinates(st_geometrycollection(list(st_point)))))
})

test_that("as.data.frame.sfc works", {
  sfc = st_sfc(st_point(0:1), st_point(3:4))
  expect_silent(as.data.frame(sfc))
})

test_that("rep.sfc works", {
  expect_equal(
	st_sfc(st_point(0:1), st_point(0:1), crs = 4326),
  	rep(st_sfc(st_point(0:1), crs=4326), 2))
})

test_that("c.sfc n_empty returns sum of st_is_empty(sfg)", {
	pt1 <- st_point(c(NA_real_, NA_real_))
	pt2 <- st_point(0:1)
	expect_equal(attr(c(st_sfc(pt1), st_sfc(pt1)), "n_empty"), 2L)
	expect_equal(attr(c(st_sfc(pt1), st_sfc(pt2)), "n_empty"), 1L)
})

test_that("st_is_longlat warns on invalid bounding box", {
	expect_warning(st_is_longlat(st_sfc(st_point(c(0,-95)), crs = 4326)))
})

test_that("bounding box is flipped when geometry is flipped", {
	foo <- st_bbox(c(xmin = 0, xmax = 100, ymin = 0, ymax = 200)) |> st_as_sfc()
	bar <- foo * matrix(c(1,0,0,-1), nrow = 2)
	expect_equal(st_bbox(bar), st_bbox(c(xmin=0, ymin=-200, xmax=100, ymax=0)))
})


