/*
 *  The Mana World Server
 *  Copyright 2004 The Mana World Development Team
 *
 *  This file is part of The Mana World.
 *
 *  The Mana World  is free software; you can redistribute  it and/or modify it
 *  under the terms of the GNU General  Public License as published by the Free
 *  Software Foundation; either version 2 of the License, or any later version.
 *
 *  The Mana  World is  distributed in  the hope  that it  will be  useful, but
 *  WITHOUT ANY WARRANTY; without even  the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 *  more details.
 *
 *  You should  have received a  copy of the  GNU General Public  License along
 *  with The Mana  World; if not, write to the  Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *  $Id$
 */

#ifndef _TMWSERV_CONTROLLER_H_
#define _TMWSERV_CONTROLLER_H_

#include "being.h"

/**
 * A controller can take control of a being.
 */
class Controller
{
    public:
        /**
         * Constructor.
         */
        Controller();

        /**
         * Take possession of the given being.
         */
        void possess(BeingPtr being);

        /**
         * Releave possession of any being.
         */
        void unPossess();

        /**
         * Performs one step of controller logic.
         */
        void update();

    private:
        BeingPtr mBeing;

        /** Count down till next random movement (temporary). */
        unsigned int mCountDown;
};

#endif // _TMWSERV_CONTROLLER_H_
