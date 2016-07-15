#ifndef SYMBTAB_H
#define SYMBTAB_H

#include <string>
#define SYMB_UNDEFINED 10

#define SYMB_FLOAT 11
#define SYMB_MATRIX 12
#define SYMB_STRING 13
#define SYMB_CHAR 14
#define SYMB_ARRAY 15
#define SYMB_FUNCTION 16

#define Z 0x00012000

struct Symb
{
	std::string name;
	int type;
	int scope;
	unsigned int dir;
	unsigned int arraySize;
	//unsigned int matrixSize;
	unsigned int functionLink;
	int returnType;
	Symb* next;
	Symb* prev;
};

class Symbtab
{
public:
	Symbtab();
	~Symbtab();
	int actualScope;
	unsigned int relativeDirR6;
	unsigned int functionLinks;
	Symb* root;
	Symb* last;
	Symb* symblook(std::string varName);
	Symb* addFunction(std::string funcName);
	void addScope();
	void quitScope();
};

#endif

