*** A Working Progress...
# Baseball-Spectator
An iOS application to display the location and statistics of MLB players on the field in real-time.

This brand new iOS baseball app rethinks the way spectators watch America’s pastime game. Baseball Spectator will ignite a newfound passion for baseball by providing an individualized, augmented reality experience for both newbies and devoted fans.

## Description
Baseball Spectator is a landscape iOS application used while spectating a baseball game in person. It enhances the ball game experience of the user by allowing them to be easily versed in the stats of the current game and the stats of each player. More specifically, while the user points their camera at the field (must have a view of at least the whole infield), it provides the real-time location of each player, their corresponding individual information and statistics,  and a virtual scoreboard. The target audience is either devoted baseball fans who are curious for a deeper analysis of the game or nieve fans who are simply looking for basic information about the current game.

# Capabilities

## User End
- Display real-time position of players through a circle indicator placed underneath each player
- Click on the player indicator to show a player info bar (player name and number)
- Click on the player info bar to open up an expanded view of the individual player’s statistics
- Display the current score, inning number, outs, strikes, and balls in a scoreboard in the top left
- Click on the scoreboard to open up an expanded inning by inning scoreboard with additional game statistics
- (For app demonstration purposes) Import your own video from storage for analysis through the import button on the top right of the screen
Toggle between displaying stats for fielders versus batters

## Developer End
- Retrieve realtime game stats from an MLB administered website
- https://www.baseball-reference.com/ for player images, historic statistics, and game score information
- Locate the coordinates of each of the players on the field, each of the infield bases, and each of the locations players are expected to be standing
- Identify the user’s location (which stadium) using their phone GPS

## TODO (desired but uncompleted capabilities)
- Automatically identify which base is home plate without the user manually selecting home plate
- Identify which players are on which team (for now, the app uses a toggle button to switch between defense and offense)
- Make the color thresholding for image processing more adaptable to varying lighting conditions (right now the thresholding works well with the exception of dark overcasting shadows -- however, shadows should not be much of a problem since when large shadows start appearing on the field, the stadium light are quickly turned on, fixing the problem)

# App View Descriptions

## Main View
Displays the scoreboard and camera footage marked up with the player indicators. This view is the central view of the app that provides navigation links/buttons pointing to the two main expanded views. If a player indicator is tapped, a brief statistics bar opens up. If the brief statistics bar is tapped, the player statistics expanded view opens up. If the scoreboard in the upper left is tapped, the scoreboard expanded view opens. It also has a toggle that allows the user to toggle between seeing the batters versus hitters.

## Scoreboad Expanded View
Displays in a higher level of detail the current score of the game, including inning by inning scores, total errors of each team, and more.

## Player Statistics Expanded View
Displays in a higher level of detailed information about the selected player including their picture, current game stats, 2020 season statistics, and career statistics. The view also displays a brief overview of the entire team’s statistics at the bottom including their number of wins, losses, percent wins, and current league standings.
