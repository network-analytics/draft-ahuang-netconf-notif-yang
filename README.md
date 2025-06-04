```shell
$ pyang ietf-yp-notification@2025-06-04.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
$ pyang ietf-yp-observation@2025-06-04.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
```

```shell
$ pyang example-foo-extension.yang -f tree  --yang-line-length=69 --keep-comments -p dependencies --tree-print-structures --tree-line-length=69
```


Format for Datatracker
```shell
$ pyang ietf-yp-notification@2025-06-04.yang -f yang --yang-line-length=69 -p dependencies
$ pyang ietf-yp-observation@2025-06-04.yang -f yang --yang-line-length=69 -p dependencies
$ pyang example-foo-extension.yang -f yang --yang-line-length=69 -p dependencies
```
