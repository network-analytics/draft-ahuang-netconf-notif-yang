```shell
$ pyang ietf-notification.yang -f tree -p dependencies
$ pyang ietf-notification.yang --tree-print-structures -f tree -p dependencies
```


```shell
$ pyang ietf-notification-envelope@2025-01-15.yang -f tree -p dependencies --tree-line-length=69
$ pyang ietf-notification-envelope@2024-10-14.yang -f tree -p dependencies --tree-line-length=69
$ pyang ietf-yp-notification@2025-02-24.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
$ pyang ietf-yp-observation@2025-02-24.yang -f tree -p dependencies --tree-line-length=69 --tree-print-structures
```

```shell
$ pyang example-foo-extension.yang -f tree  --yang-line-length=69 --keep-comments -p dependencies --tree-print-structures --tree-line-length=69
```
