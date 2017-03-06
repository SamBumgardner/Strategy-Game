# Strategy-Game
This is a Fire Emblem-style turn-based strategy game created in a semester (roughly 16 weeks) by Sam Bumgardner and Alex Mullins, a pair of students from Missouri State University.

The goal of this project is to put together a complete game with enough polish to release on a digital distribution platform such as Steam, GOG, the Humble Bundle Store, or something else.

## Overview

Lead a ragtag team of heroes against overwhelming odds in a turn-based strategy/RPG hybrid!

The game does not currently have a playable demo but you can build and run the game by following the steps below.

## Getting Started

To build and run Strategy-Game on Windows or Linux (note: only tested on Windows), follow the steps below:

1. Ensure you have [Haxe](http://www.haxe.org/download) and [HaxeFlixel](http://www.haxeflixel.com) installed on your computer.
  * Installing HaxeFlixel should also automatically install [OpenFl](http://www.openfl.org/learn/docs/getting-started/) and [Lime](https://lib.haxe.org/p/lime).
  * After HaxeFlixel's installation has finished, open a new command prompt and run `haxelib install flixel-addons` to install an additional library of extra HaxeFlixel features.
3. Clone or download this repository to your computer.	
4. Open a command prompt in the newly created `\Strategy-Game` folder.
5. Run the command `haxelib run lime test neko` to build and run the executable.
  * The executable is located in `\Strategy-Game\export\windows\neko\bin`.
  * To run in debug mode, run the command `haxlib run lime test -debug neko`. The debug console can be accessed with the backquote key.
  
## Contribution guidelines

If you're interested in making contributions to this game, please follow the steps outlined below.

* Fork this repository using the button at the top-right part of the page.
* Create a branch off of `master` with a name that describes what sort of changes you plan to make.
* Make changes/additions/deletions, committing them to your branch as you go. 
 * Aim to make your commits atomic, each dealing with a single subject.
* When finished, come back to this repository and open a pull request from your branch to `master`.
 * See existing pull requests for a general format to follow.
* Your pull request will be reviewed, responded to, and hopefully merged in!

## Contacts

* [@SamBumgardner](https://github.com/SamBumgardner) - Programmer and Designer.
* Alex Mullins - Artist and Designer.

Feel free to send me an email at sambumgardner1@gmail.com!
