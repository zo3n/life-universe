# life-universe
MTA:SA Project of simulated universe with pixel life organisms which have evolutionary traits and mechanics such as eating, breeding, mutation, etc.

You can find the preview of how it looks here:
https://www.youtube.com/watch?v=MR570-dwXOQ

## Notes
- You need to define **'p_fps'** element data for player because this resource depends on it in order to disable reproducing(breeding) when fps goes too low. That mechanism exists as a maintenance for the universe in order to prevent lag, crashes and overpopulation.
- After a certain amount of times, a "lucky" zone will appear where bunch of life will begin massively reproducing which will logically cause an fps spike aka the fps will go to pretty low values and then the safety mechanism of disabling reproduction will kick in where after some time life will self regulate itself to a point of stability once again and then reproduction will be enabled again automatically
