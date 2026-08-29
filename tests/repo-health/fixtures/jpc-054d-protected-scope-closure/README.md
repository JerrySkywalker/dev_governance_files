# Sanitized 054D protected-scope closure fixture

`accepted/` is a closed 14-file synthetic coordination root.  It contains no
credentials, endpoints, devices, browser material, raw CI output, or product
repository checkout.  Tests copy it to a temporary directory and create their
history destination as a sibling so that Close never touches this fixture.
