this time we're running tests from meshStack hub. 
we ship completely tested BBs, folder structure

- buildingblock
- backplane
- e2e 

The e2e tests are "shippable". not only do we run them in ci/cd against latest version of meshstack + terraform but the tests also serve as smoke tests for already deployed versions of the building block. pinning by the hub git_ref version makes this possible

Because we have so many tests we have to focus on just one

 tg test -- --filter=tests/building_block_noop_hub.tftest.hcl