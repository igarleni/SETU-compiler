#include "symbtab.h"

Symbtab::Symbtab()
{
	actualScope = 0;
	root = NULL;
	last = NULL;
	functionLinks = 0;
	relativeDirR6 = 0;
}

Symbtab::~Symbtab()
{
	Symb *item = root;
	if(item != NULL)
	{
		while (item->next != NULL)
		{
			item = item->next;
			delete root;
			root = item;
		}
		delete root;
	}
}

Symb* Symbtab::symblook(std::string varName)
{
	if (root == NULL)
	{
		root = new Symb();
		root->name = varName;
		root->scope = actualScope;
		root->type = SYMB_UNDEFINED;
		root->dir = 0;
		root->next = NULL;
		root->prev = NULL;
		last = root;
		return root;
	}
	Symb* item = root;
	while (item->name != varName)
	{
		if (item->next == NULL)
		{
			Symb *result = new Symb();
			result->name = varName;
			result->scope = actualScope;
			result->type = SYMB_UNDEFINED;
			result->dir = 0;
			result->next = NULL;
			result->prev = item;
			item->next = result;
			last = result;
			return result;
		}
		item = item->next;
	}
	return item;
}

Symb* Symbtab::addFunction(std::string funcName)
{
	if (root == NULL)
	{
		root = new Symb();
		root->name = funcName;
		root->scope = 0;
		root->type = SYMB_FUNCTION;
		functionLinks++;
		root->functionLink = functionLinks;
		root->next = NULL;
		root->prev = NULL;
		last = root;
		return root;
	}
	Symb* item = root;
	while (item->name != funcName)
	{
		if (item->next == NULL || item->scope > 0)
		{
			Symb *result = new Symb();
			result->name = funcName;
			result->scope = 0;
			result->type = SYMB_FUNCTION;
			result->next = root;
			result->prev = NULL;
			functionLinks++;
			result->functionLink = functionLinks;
			root->prev = result;
			root = result;
			return result;
		}
		item = item->next;
	}
	return item;
}

void Symbtab::quitScope()
{
	Symb *item = last;
	Symb *itemToDelete;
	if (actualScope != 0)
	{
		actualScope--;
		while (item != NULL)
		{
			if (item->scope > actualScope)
			{
				itemToDelete = item;
				item = item->prev;
				if (item != NULL)
				{
					item->next = NULL;
					relativeDirR6 = item->dir;
				}
				else
				{
					root = NULL;
					last = NULL;
				}
				delete itemToDelete;
				last = item;
			}
			else
				item = item->prev;
		}
	}
}

void Symbtab::addScope()
{
	actualScope++;
	relativeDirR6 = 0;
}
