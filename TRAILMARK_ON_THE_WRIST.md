# TrailMark on the Wrist

Course 2 integration report.

## What got reused

The whole point of this one was to not rewrite anything. The watch app pulls 7 types and managers straight out of TrailMarkCH10Core with zero changes:

`HealthKitManager`, `MediaStore`, `ActivitySummary`, `AudioRecorder`, `AudioPlayer`, `MediaMemo`, `MemoKind`

Those live in 6 source files in the package. The watch adds 5 files of its own, and every one of them is a view:

`ContentView.swift`, `WristHomeView.swift`, `WristMemoView.swift`, `LiveVitalsView.swift`, `MotionView.swift`

So the ratio is 6 reused core files to 5 watch specific view files. Nothing in that watch list knows how to record audio, write to disk, or query HealthKit. It all calls into the package. The only thing I added to the core was live streaming on `HealthKitManager`, and that was additive, the existing `sumQuantity` and `refreshTodaysSummary` are untouched.

Worth saying out loud: the recording on the watch goes through the same `MediaStore.add` the phone uses, writing the same `MediaMemo` to the same JSON index. One model, two faces.

## Design decision I want to defend

Wrist Home shows one number and one button. That's it. Steps today in big rounded type, and a Record button underneath.

On the phone that same screen is a stack of `MetricCard` views, steps and distance and active energy, all visible at once. Dropping two of the three cards felt wrong when I did it, so here's why I did it anyway.

Apple's watchOS Human Interface Guidelines open with glanceability under "Designing for watchOS," and the principle is that people use the watch in short bursts, a few seconds at a time, usually while doing something else. The guidance is to surface one piece of information the person came for and let everything else live a tap away. Three cards on a 46mm screen means three small numbers, and small numbers at arm's length while walking are just noise. One large number is readable before you've finished raising your wrist.

The other half of the same call was deciding not to make the home screen scroll. The HIG treats the Digital Crown as the primary way to move through content, but if the headline metric requires any crown movement to reach, it isn't a headline anymore. So distance and energy moved to the Vitals screen behind a nav link, and home fits on one screen with nothing cut off.

Tradeoff I'm accepting: you get less at a glance than on the phone. That's the right call for a device you look at for two seconds and the wrong call for one you hold for two minutes.

## Note on sensor cost


Motion sampling has a dial on it. `deviceMotionUpdateInterval` is set to 0.2 seconds, so 5 samples a second. Core Motion will happily run at 50 or 100Hz, and for what I'm doing, telling still from walking from active, that's 10 to 20 times more data than the signal needs. Every one of those samples wakes the CPU. On a watch that's the difference between making it to bedtime and not.

Same thinking on heart rate. The live vitals screen uses `HKAnchoredObjectQuery` with an update handler rather than re polling on a timer. HealthKit pushes new samples when they arrive, so the app isn't asking a question every second and getting the same answer back.

Both motion and vitals stop their updates in `onDisappear`. Leaving a device motion stream running behind a screen nobody is looking at is the easiest battery mistake to make and the hardest one to notice.
