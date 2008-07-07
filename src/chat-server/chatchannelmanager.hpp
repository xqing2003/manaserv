/*
 *  The Mana World Server
 *  Copyright 2004 The Mana World Development Team
 *
 *  This file is part of The Mana World.
 *
 *  The Mana World is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  any later version.
 *
 *  The Mana World is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with The Mana World; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  $Id$
 */

#ifndef _TMWSERV_CHATCHANNELMANAGER_H_
#define _TMWSERV_CHATCHANNELMANAGER_H_

#include <list>
#include <map>
#include <deque>

#include "chat-server/chatchannel.hpp"

/**
 * The chat channel manager takes care of registering and removing public and
 * private chat channels. Every channel gets a unique channel ID.
 */
class ChatChannelManager
{
    public:
        /**
         * Constructor.
         */
        ChatChannelManager();

        /**
         * Destructor.
         */
        ~ChatChannelManager();

        /**
         * Create a new chat channel.
         *
         * @return the ID of the registered channel
         */
        int createNewChannel(const std::string &channelName,
                                    const std::string &channelAnnouncement,
                                    const std::string &channelPassword,
                                    bool joinable);

        /**
         * Try to create a new public channel with the given name.
         *
         * @return true if created successfully, false otherwise.
         */
        bool tryNewPublicChannel(const std::string &name);

        /**
         * Remove a channel.
         */
        bool removeChannel(int channelId);

        /**
         * Returns a list containing all public channels.
         *
         * @return a list of all public channels
         */
        std::list<const ChatChannel*> getPublicChannels();

        /**
         * Get the id of a channel from its name.
         *
         * @return the id of the channel, 0 if it was unsuccessful.
         */
        int getChannelId(const std::string &channelName);

        /**
         * Returns the chat channel with the given channel ID.
         *
         * @return The chat channel, or NULL when it doesn't exist.
         */
        ChatChannel* getChannel(int channelId);

        /**
         * Returns the chat channel with the given channel name.
         *
         * @return The chat channel, or NULL when it doesn't exist.
         */
        ChatChannel* getChannel(const std::string &name);

        /**
         * Remove a user from all channels. Used at logout.
         *
         * @see ChatChannel::removeUserFromChannel
         */
        void removeUserFromAllChannels(ChatClient *);

        /**
         * Set the topic of a channel.
         *
         * @param topic the new topic of the given channel
         */
        void setChannelTopic(int channelId, const std::string &name);

        /**
         * Returns whether a channel exists.
         *
         * @param channelId a channel ID
         */
        bool channelExists(int channelId);
        bool channelExists(const std::string &channelName);

        /**
         * Get next usable channel ID
         */
        int nextUsable();

    private:
        typedef std::map<unsigned short, ChatChannel> ChatChannels;
        typedef ChatChannels::iterator ChatChannelIterator;

        /**
         * The map keeping all the chat channels. The channel id must be
         * unique.
         */
        ChatChannels mChatChannels;
        int mNextChannelId;
        std::deque<int> mChannelsNoLongerUsed;
};

extern ChatChannelManager *chatChannelManager;

#endif
