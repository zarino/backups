#include <stdio.h>

int main(void) {
  FILE *p;
  int ch;

  p = popen("../backup.sh", "r");
  while( (ch=fgetc(p)) != EOF) {
    putchar(ch);
  }
  pclose(p);

  p = popen("../maintain.sh", "r");
  while( (ch=fgetc(p)) != EOF) {
    putchar(ch);
  }
  pclose(p);

  return(0);
}
