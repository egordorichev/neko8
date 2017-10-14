#### Guys, this branch is used for porting **neko8** to **c++**. It is not stable or usable yet, we will announce, when it will be.


# neko8

![](https://media.discordapp.net/attachments/314487938949971980/355710597528027146/Peek_2017-09-08_16-43.gif)

[**Neko8**](https://egordorichev.itch.io/neko8) is a **fantasy console**, inspired by [**pico8**](https://www.lexaloffle.com/pico-8.php), [**liko12**](https://ramilego4game.itch.io/liko12) and [**tic80**](https://tic.computer/). It is open-source and fully free. Its goal is to be a fun and useful tool for game development and **especially for game jams**. 

[![](https://media.discordapp.net/attachments/356934835052478470/358195024808116225/Screenshot_2017-09-15_at_1.18.32_PM.png)](https://egordorichev.itch.io/neko8)

Currently it features:

* Pico8-like api
* Code editor
* Sprite editor
* Map editor prototype
* Terminal
* Build-in API docs
* Support for both lua and asm programming (planning add BASIC support)
* Some easter eggs ;)

Our developers can be found on [discord](https://discord.gg/DPBN8Xn).

#### Installing ang running

Download and extract the source. In the root folder run:

```
love .
```

You will need **löve2d 0.10.2** to run **neko8**. Löve2d version is really important!

### Contributing

If you'd like to contribute to **neko8**, feel free to fork and make pull
requests! However, we ask you to follow the formatting guidelines for this
project. 

 - Use non-expanded, i.e. the regular, tabs.
 - Keep a maximum line length of 80 characters.
 - Double quotes are preferred over single quotes.
 - Don't use concatenation where `string.format` would be more beneficial.
 - If unsure how to format something, check how it's formatted in existing code.
