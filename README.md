anim8
=====

anim8 is a jQuery plugin that makes it easy to do sprite based animations using
the `<canvas>` tag. 

At FutDut Games we use HTML5. Often our games have small ambient things that are
animated and have multiple levels of alpha that makes gif animations unsuitable. 

We created anim8 to provide a more powerful and tweakable loop based animation
that allows us to turn `<canvas>` tags into looping animations. 

This is still a very early project but checkout the demos and the sources for
examples of it in action.

Requirements
============

The only dependency (and it's a big one) is TexturePacker. We use TexturePacker
to create a packed image of sprites and a json based index on the frames. For
our games this allows us to reduce the the number of network calls and files
loaded. 
