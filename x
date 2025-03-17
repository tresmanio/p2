import pygame
import random
import pygame_gui
import sys

pygame.init()  # initialises pygame
screen = pygame.display.set_mode((1280, 720))  # sets the size of the screen
pygame.display.set_caption("poker screen")  # sets the caption of the screen
blue = (128, 128, 255)  # a constant blue rgb value
base_font = pygame.font.Font(None, 100)  # sets the font and size of the text
clock = pygame.time.Clock()  # sets the clock
manager = pygame_gui.UIManager((1280, 720))  # creates a UI manager

# Create a text input box for the bet amount (initially hidden)
bet_input = pygame_gui.elements.UITextEntryLine(
    relative_rect=pygame.Rect((500, 300), (280, 50)),
    manager=manager,
    object_id='#bet_input'
)
bet_input.hide()  # Hide the text input box initially

# Load images and resize them
startIMG = pygame.image.load('start.png').convert_alpha()
statsIMG = pygame.image.load('stats.png').convert_alpha()
optionsIMG = pygame.image.load('options.png').convert_alpha()
bet = pygame.image.load('bet.png').convert_alpha()
fold = pygame.image.load('fold.png').convert_alpha()

startIMG = pygame.transform.scale(startIMG, (400, 100))
optionsIMG = pygame.transform.scale(optionsIMG, (400, 100))
statsIMG = pygame.transform.scale(statsIMG, (400, 100))
bet = pygame.transform.scale(bet, (100, 100))
fold = pygame.transform.scale(fold, (100, 100))


class Image():
    def __init__(self, x, y, image):
        self.image = image
        self.rect = self.image.get_rect()
        self.rect.topleft = (x, y)

    def draw(self, surface):
        surface.blit(self.image, (self.rect.x, self.rect.y))

    def is_clicked(self):
        if pygame.mouse.get_pressed()[0]:
            if self.rect.collidepoint(pygame.mouse.get_pos()):
                return True
        return False


class Screen():
    def __init__(self, game):
        self.game = game
        self.font = pygame.font.Font(None, 74)
        self.flop_cards = []

    def update_flop(self):
        self.flop_cards = []
        for i, card in enumerate(self.game.flop):
            suit = card[0].lower()
            suit_names = {"c": "club", "d": "diamond", "h": "hearts", "s": "spades"}
            suit = suit_names.get(suit, "unknown")
            cardIMG = pygame.image.load(f'CARDS/{suit}/{card}.png').convert_alpha()
            cardIMG = pygame.transform.scale(cardIMG, (100, 150))
            self.flop_cards.append(Image(400 + 120 * i, 250, cardIMG))

    def main_menu(self):
        screen.fill((57, 79, 145))
        text = self.font.render("poker", True, (255, 255, 255))
        screen.blit(text, (500, 100))
        sb.draw(screen)
        ob.draw(screen)
        stb.draw(screen)

    def game_screen(self):
        screen.fill((0, 128, 128))
        bet.draw(screen)
        fold.draw(screen)
        for card in self.flop_cards:
            card.draw(screen)
        for card in opponent_cards:
            card.draw(screen)
        for card in player1_cards:
            card.draw(screen)

    def options_screen(self):
        screen.fill((50, 50, 50))
        text = self.font.render("Options Screen", True, (255, 255, 255))
        screen.blit(text, (500, 300))

    def stats_screen(self):
        screen.fill((0, 0, 128))
        text = self.font.render("Stats Screen", True, (255, 255, 255))
        screen.blit(text, (500, 300))


class Deck():
    def __init__(self):
        self.deck = []
        self.create_deck()

    def create_deck(self):
        self.deck = []
        for suit in ["C", "D", "H", "S"]:
            for j in range(1, 14):
                if j == 1:
                    j = "A"
                elif j == 11:
                    j = "J"
                elif j == 12:
                    j = "Q"
                elif j == 13:
                    j = "K"
                self.deck.append(suit + str(j))
        return self.deck

    def shuffle_deck(self):
        random.shuffle(self.deck)
        return self.deck

    def deal_card(self, holder):
        for i in range(2):
            card = self.deck.pop(random.randint(0, len(self.deck) - 1))
            holder.hand.append(card)


class Game:
    def __init__(self):
        self.flop = []
        self.pot = 0
        self.flop_phase = 0  # 0: pre-flop, 1: flop, 2: turn, 3: river

    def add(self, bet_amount):
        self.pot += bet_amount

    def deal_flop(self, num):
        deck = Deck()
        for i in range(num):
            card = deck.deck.pop(random.randint(0, len(deck.deck) - 1))
            self.flop.append(card)

    def advance_phase(self):
        if self.flop_phase == 0:
            # Deal the initial flop (3 cards)
            self.deal_flop(3)
        elif self.flop_phase == 1:
            # Deal the turn (1 card)
            self.deal_flop(1)
        elif self.flop_phase == 2:
            # Deal the river (1 card)
            self.deal_flop(1)
        self.flop_phase += 1


class Player():
    def __init__(self, name, win, loss):
        self.name = name
        self.hand = []
        self.chips = 100
        self.win = win
        self.loss = loss
        self.id = 0

    def bet(self, amount):
        if amount > self.chips:
            print("Invalid bet: Not enough chips.")
            return 0
        self.chips -= amount
        print(f"{self.name} bets {amount} chips.")
        return amount

    def fold(self):
        self.hand = []
        print(f"{self.name} folds.")

    def check(self):
        pass


class AI(Player):
    def __init__(self, name, win, loss):
        super().__init__(name, win, loss)
        self.decision_threshold = 0.5

    def calculate_win_probability(self, game):
        combined_cards = self.hand + game.flop
        potential_winning_cards = 0
        for card in combined_cards:
            if card[1:] in ['A', 'K', 'Q', 'J', '10']:
                potential_winning_cards += 1
        win_probability = potential_winning_cards / len(combined_cards)
        return win_probability

    def make_decision(self, game):
        win_probability = self.calculate_win_probability(game)
        if win_probability > self.decision_threshold:
            bet_amount = min(self.chips, 10)
            self.chips -= bet_amount
            game.add(bet_amount)
            print(f"{self.name} bets {bet_amount} chips.")
            return "bet"
        elif win_probability > 0.3:
            print(f"{self.name} checks.")
            return "check"
        else:
            self.fold()
            print(f"{self.name} folds.")
            return "fold"


# Create buttons
sb = Image(440, 380, startIMG)
ob = Image(440, 470, optionsIMG)
stb = Image(440, 580, statsIMG)
bet = Image(1000, 500, bet)
fold = Image(100, 500, fold)

# Initialize players
player1 = Player("Player 1", 0, 0)
ai_player = AI("AI Player", 0, 0)

# Initialize game
game = Game()
cards = Deck()
cards.shuffle_deck()

# Deal cards to players
cards.deal_card(player1)
cards.deal_card(ai_player)

# Load and create card images for the opponent's face-down cards
opponent_cards = []
backIMG = pygame.image.load('CARDS/back.png').convert_alpha()
backIMG = pygame.transform.scale(backIMG, (100, 150))
for i in range(2):
    opponent_cards.append(Image(540 + 120 * i, 50, backIMG))

# Load and create card images for the player's hand
player1_cards = []
for i in range(len(player1.hand)):
    suit = player1.hand[i][0].lower()
    value = player1.hand[i]
    suit_names = {"c": "club", "d": "diamond", "h": "hearts", "s": "spades"}
    suit = suit_names.get(suit, "unknown")
    cardIMG = pygame.image.load(f'CARDS/{suit}/{value}.png').convert_alpha()
    cardIMG = pygame.transform.scale(cardIMG, (100, 150))
    player1_cards.append(Image(300 + 120 * i, 500, cardIMG))

# Main game loop
current_screen = "main_menu"
game_running = True
player_turn = True
betting = False  # Track if the player is currently betting
screens = Screen(game)

while game_running:
    time_delta = clock.tick(60) / 1000.0
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            game_running = False
            pygame.quit()
            sys.exit()

        manager.process_events(event)

        if event.type == pygame_gui.UI_TEXT_ENTRY_FINISHED and event.ui_object_id == '#bet_input':
            try:
                bet_amount = int(event.text)
                if 0 < bet_amount <= player1.chips:
                    player1.bet(bet_amount)
                    game.add(bet_amount)
                    betting = False
                    bet_input.hide()
                    player_turn = False  # Switch to AI's turn
            except ValueError:
                print("Invalid input: Please enter a valid number.")

    manager.update(time_delta)

    if current_screen == "main_menu":
        screens.main_menu()
        if sb.is_clicked():
            current_screen = "game"
        elif ob.is_clicked():
            current_screen = "options"
        elif stb.is_clicked():
            current_screen = "stats"

    elif current_screen == "game":
        screens.game_screen()

        if player_turn:
            if bet.is_clicked():
                betting = True
                bet_input.show()
            elif fold.is_clicked():
                player1.fold()
                player_turn = False
        else:
            ai_decision = ai_player.make_decision(game)
            if ai_decision == "bet":
                player_turn = True
            elif ai_decision == "check":
                player_turn = True
            elif ai_decision == "fold":
                player_turn = True

        # Check if both players have made their moves
        if not player_turn and not betting:
            game.advance_phase()  # Advance to the next flop phase
            screens.update_flop()  # Update the flop display
            player_turn = True  # Reset for the next round

    elif current_screen == "options":
        screens.options_screen()

    elif current_screen == "stats":
        screens.stats_screen()

    manager.draw_ui(screen)
    pygame.display.flip()
