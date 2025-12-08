# odin-osc

A pure Odin implementation of the [OSC(Open Sound Control) 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html) protocol.

Ported from [funatsufumiya/osc](https://github.com/funatsufumiya/osc)

## Usage

### Sender

see [sender example](./examples/example_sender/main.odin).

### Receiver (using filter)

#### filter messages

see [filter messages example](./examples/example_receiver_filter_msg/main.odin).

#### filter addresses

see [filter addresses example](./examples/example_receiver_filter_addr/main.odin).

### Receiver (plain)

see [plain receiver example](./examples/example_receiver_plain/main.odin).

## Tests

```bash
$ odin test tests
```

## License

see [LICENSE](./LICENSE).

Please note that the original [Okabintaro/nosc](https://github.com/Okabintaro/nosc) (base code of [osc](https://github.com/funatsufumiya/osc)) contains codes by [treeform](https://github.com/treeform) codes, see [LICENSE_treeform](./LICENSE_treeform) and [original README](https://github.com/Okabintaro/nosc/blob/master/README.md).
