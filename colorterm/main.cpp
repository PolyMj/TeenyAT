#include <iostream>
#include <cstdlib>

#include "teenyat.h"
#include "rogueutil.h"

using namespace std;
using namespace rogueutil;

/*
 *  
 *  SET_FG_COLOR
 *  - 0x9000
 *  - Set the foreground color of future characters
 *  - Write-only
 *  
 *  SET_BG_COLOR
 *  - 0x9001
 *  - Set the background color of future characters
 *  - Write-only
 *  
 *  CLEAR_SCREEN
 *  - 0x9002
 *  - Write any value to clear screen to BG color, cursor to 0, 0
 *  - Write-only
 *  
 *  SET_CHAR
 *  - 0x9003
 *  - Set/stamp a character at the cursor, which doesn't move
 *  - Write-only
 *  
 *  PRINT_CHAR
 *  - 0x9004
 *  - Draw character at cursor and advance x coordinate
 *  - Write-only
 *  
 *  CURSOR_VIS
 *  - 0x9005
 *  - 0: cursor off, non-zero: cursor visible
 *  - Read and Write
 *  
 *  SET_TITLE
 *  - 0x9006
 *  - Add characters to the window title bar
 *  - Write-only
 *  
 *  X
 *  - 0x9007
 *  - Get/set the cursor x.  Wraps at right edge
 *  - Read and Write
 *  
 *  Y
 *  - 0x9008
 *  - Get/set the cursor y.  Wraps at bottom edge
 *  - Read and Write
 *  
 *  KEY_CNT
 *  - 0x9009
 *  - get number of keys buffered
 *  - Read-only
 *  
 *  GET_KEY
 *  - 0x900A
 *  - get a key from the buffer
 *  - Read-only
 * 
 *  MOVE_E
 *  - 0x9010
 *  - Move to the east
 *  - Write-only (strobe)
 * 
 *  MOVE_SE
 *  - 0x9011
 *  - Move to the south-east
 *  - Write-only (strobe)
 * 
 *  MOVE_S
 *  - 0x9012
 *  - Move to the south
 *  - Write-only (strobe)
 * 
 *  MOVE_SW
 *  - 0x9013
 *  - Move to the south-west
 *  - Write-only (strobe)
 * 
 *  MOVE_W
 *  - 0x9014
 *  - Move to the west
 *  - Write-only (strobe)
 * 
 *  MOVE_NW
 *  - 0x9015
 *  - Move to the north-west
 *  - Write-only (strobe)
 * 
 *  MOVE_N
 *  - 0x9016
 *  - Move to the north
 *  - Write-only (strobe)
 * 
 *  MOVE_NE
 *  - 0x9017
 *  - Move to the north-east
 *  - Write-only (strobe)
 * 
 *  MOVE
 *  - 0x9020
 *  - Move the cursor one cell in the direction specified by the value written
 *  - | VAL |...| -5 | -4 | -3 | -2 | -1 |  0 |  1 |  2 |  3 |...|
 *    | DIR |...| SW |  W | NW |  N | NE |  E | SE |  S | SW |...|
 */


#define SET_FG_COLOR    0x9000
#define SET_BG_COLOR    0x9001
#define CLEAR_SCREEN    0x9002
#define SET_CHAR        0x9003
#define PRINT_CHAR      0x9004
#define CURSOR_VIS      0x9005
#define SET_TITLE       0x9006
#define X               0x9007
#define Y               0x9008
#define KEY_CNT         0x9009
#define GET_KEY         0x900A
#define MOVE_E          0x9010
#define MOVE_SE         0x9011
#define MOVE_S          0x9012
#define MOVE_SW         0x9013
#define MOVE_W          0x9014
#define MOVE_NW         0x9015
#define MOVE_N          0x9016
#define MOVE_NE         0x9017
#define MOVE            0x9020

#ifdef TEXT_PADDING
    #define TEXT_PADDING_LOWER    TEXT_PADDING
    #define TEXT_PADDING_UPPER    TEXT_PADDING
#else
    #ifndef TEXT_PADDING_LOWER
        #define TEXT_PADDING_LOWER 0
    #endif
    #ifndef TEXT_PADDING_UPPER
        #define TEXT_PADDING_UPPER 0
    #endif
#endif


#define gotoxy_pad(x,y)   gotoxy(x+(int)(TEXT_PADDING_LOWER), y+(int)(TEXT_PADDING_LOWER))

enum Direction {
    East = 0,
    SouthEast,
    South,
    SouthWest,
    West,
    NorthWest,
    North,
    NorthEast
};

int x = TEXT_PADDING_LOWER;
int y = TEXT_PADDING_LOWER;

bool cursor_visible = true;

string title = "";




void bus_write(teenyat *t, tny_uword addr, tny_word data, uint16_t *delay);
void bus_read(teenyat *t, tny_uword addr, tny_word *data, uint16_t *delay);

int main(int argc, char *argv[]) { 
    saveDefaultColor();
    setConsoleTitle("TeenyAT Color Terminal");
    cls();

    setvbuf(stdout, NULL, _IONBF, 0);

    FILE *bin_file = fopen(argv[1], "rb");
	teenyat t;
	tny_init_from_file(&t, bin_file, bus_read, bus_write);

    setCursorVisibility(cursor_visible);

    for(;;) {
        tny_clock(&t);
    }

    resetColor();
    cls();
    return EXIT_SUCCESS;
}


// Move the cursor in the given direction
void move_cursor(Direction dir)
{
    switch(dir)
    {
    case Direction::East:
        x += 1;
        break;
    case Direction::SouthEast:
        x += 1;
        y += 1;
        break;
    case Direction::South:
        y += 1;
        break;
    case Direction::SouthWest:
        x -= 1;
        y += 1;
        break;
    case Direction::West:
        x -= 1;
        break;
    case Direction::NorthWest:
        x -= 1;
        y -= 1;
        break;
    case Direction::North:
        y -= 1;
        break;
    case Direction::NorthEast:
        x += 1;
        y -= 1;
        break;
    default:
        return;
    }

    int tc = tcols() - (TEXT_PADDING_LOWER + TEXT_PADDING_UPPER);
    int tr = trows() - (TEXT_PADDING_LOWER + TEXT_PADDING_UPPER);
    x = (x + tc) % tc;
    y = (y + tr) % tr;
    gotoxy_pad(x,y);
}


void bus_write(teenyat *t, tny_uword addr, tny_word data, uint16_t *delay) {
    switch(addr) {
    case SET_FG_COLOR:
        setColor(data.u);
        break;
    case SET_BG_COLOR:
        setBackgroundColor(data.u);
        break;
    case CLEAR_SCREEN:
        cls();
        x = 0;
        y = 0;
        break;
    case SET_CHAR:
        cout << (char)data.u;
        gotoxy_pad(x, y);
        break;
    case PRINT_CHAR:
        cout << (char)data.u;
        x = (x + 1) % tcols();
        gotoxy_pad(x, y);
        break;
    case CURSOR_VIS:
        cursor_visible = data.u;
        setCursorVisibility(cursor_visible);
        break;
    case SET_TITLE:
        title += (char)(data.bytes.byte0);
        setConsoleTitle(title.c_str());
        break;
    case X:
        x = data.u % tcols();
        gotoxy_pad(x, y);
        break;
    case Y:
        y = data.u % trows();
        gotoxy_pad(x, y);
        break;
    case MOVE_E:
        move_cursor(Direction::East);
        break;
    case MOVE_SE:
        move_cursor(Direction::SouthEast);
        break;
    case MOVE_S:
        move_cursor(Direction::South);
        break;
    case MOVE_SW:
        move_cursor(Direction::SouthWest);
        break;
    case MOVE_W:
        move_cursor(Direction::West);
        break;
    case MOVE_NW:
        move_cursor(Direction::NorthWest);
        break;
    case MOVE_N:
        move_cursor(Direction::North);
        break;
    case MOVE_NE:
        move_cursor(Direction::NorthEast);
        break;
    case MOVE:
        move_cursor((Direction)(data.u & 0x7)); // More efficient modulus by 8
        break;
    default:
        break;
    }

    return;
}


void bus_read(teenyat *t, tny_uword addr, tny_word *data, uint16_t *delay) {
    switch(addr) {
    case X:
        data->s = x;
        break;
    case Y:
        data->s = y;
        break;
    case CURSOR_VIS:
        data->u = cursor_visible;
        break;
    case KEY_CNT:
        data->u = kbhit();
        break;
    case GET_KEY:
        data->u = nb_getch();
    default:
        break;
    }

    return;
}
