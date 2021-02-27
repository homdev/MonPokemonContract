pragma solidity ^0.6.4;
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;

contract MonPokemon {

    // Différents états d'un pokemon
    enum EtatPokemon { EN_VENTE, EN_PASSATION, CAPTURE }

    struct Pokemon {
        uint256 id;
        address payable proprietaire; // Propriétaire
        string image; // Image hash
        string nom; // Nom Pokemon
        uint256 xp; // Xp
        uint256 prix; // Prix en wei
        EtatPokemon etat; // Etat du pokemon
    }

    event Vente(uint256 id, address ancienProprio, address nouveauProprio);
    event MiseEnVente(uint256 id, uint256 prix, uint256 date);

    // Liste dynamique des pokemons
    uint256[] private listPokemons;

    // Liste des pokemons indexée par une valeur numérique
    mapping(uint256 => Pokemon) public pokemons;
    
    // Vérifie que le pokemon existe par un boolean
    mapping(uint => bool) _idPokemonExists;
    mapping(string => bool) _nomPokemonExists;
    mapping(string => bool) _imagePokemonExists;

    mapping(address => bool) agents;

    // Fonctions uniquement utilisables par un agent agréé
    modifier estAgentAgree() {
        require(agents[msg.sender], "Doit être un agent agréé");
        _;
    }
    // Fonctions uniquement utilisables par le propriétaire du pokemon donnée
    modifier estProprietaire(uint256 _id) {
        require(pokemons[_id].proprietaire == msg.sender, "Doit être propriétaire");
        _;
    }

    constructor() public {
        agents[msg.sender] = true;
    }

    function ajouterAgentAgree(address _agent) estAgentAgree external {
        require(_agent != address(0x0), "L'adresse ne doit pas être égale à 0");
        agents[_agent] = true;
    }

    function retirerAgentAgree(address _agent) estAgentAgree external {
        agents[_agent] = false;
    }

    // Achat d'une propriété
    function acheterPokemon(uint256 _id)
        external
        payable
    {
        Pokemon memory pokemon = pokemons[_id];

        // Protège des montants à 0
        require(msg.value > 0, "Le montant ne peut être de 0");
        // Le pokemon doit être en vente
        require(pokemon.etat == EtatPokemon.EN_VENTE, "Le pokemon doit être en vente");
        // Le montant doit être exact
        require(msg.value == pokemon.prix, "Montant insuffisant ou trop élevé");
        pokemon.proprietaire.transfer(msg.value);

        emit Vente(_id, pokemon.proprietaire, msg.sender);

        changerProprietaire(_id, msg.sender);
    }

    function ajouterPokemon(
        address payable _proprietaire,
        uint256 _id,
        string calldata _image,
        string calldata _nom,
        uint256 _xp
    ) external estAgentAgree {
        // Interdiction de mettre l'identifiant à 0
        require(_id > 0, "Identifiant de la propriété 0 impossible");
        // L'identifiant ne doit pas exister déjà
        require(pokemons[_id].proprietaire == address(0x0), "Identifiant déjà utilisé");
        // Vérifie que le pokemon n'existe pas !!
        require(!_idPokemonExists[_id], "Cette id Pokemon existe !!");
        require(!_nomPokemonExists[_nom], "Ce nom de Pokemon existe !!");
        require(!_imagePokemonExists[_image], "Cette image Pokemon existe !!");
        // Prix par défaut à 0. L'achat du pokemon ne peut se faire quand un montant est à 0
        pokemons[_id] = Pokemon( _id, _proprietaire, _image, _nom, _xp, 0, EtatPokemon.CAPTURE);
        // On conserve une liste dynamique des pokemons recensées
        listPokemons.push(_id);
        // on vérifie si les attributs du pokemon existe
        _idPokemonExists[_id] = true;
        _nomPokemonExists[_nom] = true;
        _imagePokemonExists[_image] = true;
    }

    // Passe le pokemon à un nouveau proprétaire. Cette fonction est privée est n'est utilisée que lorsque un
    // pokemon est vendue
    function changerProprietaire(uint256 _id, address payable _nouveauProprietaire) private {
        require(pokemons[_id].proprietaire != address(0x0), "Pokemon inexistant");
        pokemons[_id].proprietaire = _nouveauProprietaire;
        pokemons[_id].etat = EtatPokemon.EN_PASSATION;
    }

    function declarerPokemon(uint256 _id) external estProprietaire(_id) {
        require(pokemons[_id].etat == EtatPokemon.EN_PASSATION, "Doit être en passation");
        pokemons[_id].etat = EtatPokemon.CAPTURE;
    }

    function mettrePokemonEnVente(uint256 _id, uint256 _prix) external estProprietaire(_id) {
        // Donation du pokemon impossible
        require(_prix > 0, "Le prix de vente ne peut pas être de 0");

        pokemons[_id].prix = _prix;
        pokemons[_id].etat = EtatPokemon.EN_VENTE;

        // Journalisation de la mise en vente avec la date du moment d'exécution de la fonction (now)
        emit MiseEnVente(_id, _prix, now);
    }

    function pokemonEstEnVente(uint256 _id) public view returns(bool) {
        return pokemons[_id].etat == EtatPokemon.EN_VENTE;
    }


    // Trouve les pokemons dans une localisation donnée
    // et retourne les identifiants


    // Trouve le pokemon selon l'index de la liste
    function pokemonIndex(uint256 _index) external view returns (Pokemon memory) {
        require(_index < listPokemons.length, "Index trop grand");
        return pokemons[listPokemons[_index]];
    }

    function totalPokemons() external view returns (uint256) {
        return listPokemons.length;
    }
}
