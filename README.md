# Emulator Automator
An emulator debugging tool.

## Setup
Setup build environment.

```bash
$ brew cask install android-platform-tools
$ brew install opencv
$ brew install tesseract
```

## Usage
Launch an emulator with debug mode. And try this in the `main.js`.

```js
console.log('Hello, world!');
var packages = emulator.listPackages();

for (var i = 0; i < packages.length; i++) {
	console.log(packages[i]);
}

emulator.openPackage('com.android.browser');
```


## License
Emulator Automator is released under the [MIT License](./LICENSE).