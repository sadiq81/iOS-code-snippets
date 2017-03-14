# Usage

```
let slider = Slider(titles: ["Title1", "Title2"], titleAlignment: .sides)
```

```
slider.setIndex(2)
slider.selectedValue.asObservable()
      .subscribe(onNext: { [unowned self] (_) in
          //Do Something
      })
      .addDisposableTo(self.disposeBag)
```
