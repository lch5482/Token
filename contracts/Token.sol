// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SLToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 총 공급량: 10억 개
    uint256 public tgeDate; // TGE (토큰 생성 이벤트) 날짜

    // 그룹 주소
    address public fundBuilder;
    address public teamMember;
    address public coreBuilder;
    address public ecosystemTreasury;
    address public liquidityAndStakingPool;
    address public marketingAllocation;
    address public foundationTreasury;

    // 베스팅 정보를 관리하는 구조체
    struct VestingSchedule {
        uint256 totalAmount;      // 총 베스팅 토큰 양
        uint256 initialRelease;   // 초기 릴리즈 비율
        uint256 cliffDuration;    // 클리프 기간
        uint256 vestingDuration;  // 베스팅 총 기간
        uint256 released;         // 릴리즈된 토큰 양
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    event TGEUpdated(uint256 tgeDate);
    event TokensReleased(address beneficiary, uint256 amount);

    constructor(
        address _fundBuilder,
        address _teamMember,
        address _coreBuilder,
        address _ecosystemTreasury,
        address _liquidityAndStakingPool,
        address _marketingAllocation,
        address _foundationTreasury
    ) ERC20("SL Token", "SL") Ownable(msg.sender){
        require(_fundBuilder != address(0), "Invalid address for Fund Builder");
        require(_teamMember != address(0), "Invalid address for Team Member");
        require(_coreBuilder != address(0), "Invalid address for Core Builder");
        require(_ecosystemTreasury != address(0), "Invalid address for Ecosystem Treasury");
        require(_liquidityAndStakingPool != address(0), "Invalid address for Liquidity & Staking Pool");
        require(_marketingAllocation != address(0), "Invalid address for Marketing Allocation");
        require(_foundationTreasury != address(0), "Invalid address for Foundation Treasury");

        fundBuilder = _fundBuilder;
        teamMember = _teamMember;
        coreBuilder = _coreBuilder;
        ecosystemTreasury = _ecosystemTreasury;
        liquidityAndStakingPool = _liquidityAndStakingPool;
        marketingAllocation = _marketingAllocation;
        foundationTreasury = _foundationTreasury;

        _mint(fundBuilder, (TOTAL_SUPPLY * 20) / 100);  // 20% 할당
        _mint(teamMember, (TOTAL_SUPPLY * 10) / 100);  // 10% 할당
        _mint(coreBuilder, (TOTAL_SUPPLY * 15) / 100);  // 15% 할당
        _mint(ecosystemTreasury, (TOTAL_SUPPLY * 15) / 100);  // 15% 할당
        _mint(liquidityAndStakingPool, (TOTAL_SUPPLY * 10) / 100);  // 10% 할당
        _mint(marketingAllocation, (TOTAL_SUPPLY * 10) / 100);  // 10% 할당
        _mint(foundationTreasury, (TOTAL_SUPPLY * 20) / 100);  // 20% 할당

        // Ecosystem Treasury 베스팅 스케줄 초기화
        vestingSchedules[ecosystemTreasury] = VestingSchedule({
            totalAmount: 150_000_000 * 10**18,
            initialRelease: 30_000_000 * 10**18,
            cliffDuration: 180 days,
            vestingDuration: 1200 days,
            released: 0
        });
    }

    // 상장일(TGE) 설정 함수 (여러 번 설정 가능)
    function setTGE(uint256 _tgeDate) external onlyOwner {
        require(_tgeDate > block.timestamp, "TGE date must be in the future");
        tgeDate = _tgeDate;
        emit TGEUpdated(_tgeDate);
    }

    // 현재 설정된 TGE 날짜 조회 함수
    function getTGE() external view returns (uint256) {
        return tgeDate;
    }

    // Ecosystem Treasury 토큰 릴리즈 함수
    function releaseEcosystemTokens() external {
        require(tgeDate != 0, "TGE date is not set");
        require(block.timestamp >= tgeDate, "Vesting has not started yet");

        VestingSchedule storage schedule = vestingSchedules[ecosystemTreasury];
        require(schedule.totalAmount > 0, "No tokens to vest");

        uint256 releasable = _calculateEcosystemReleasableAmount(schedule);
        require(releasable > 0, "No tokens available for release");

        schedule.released += releasable;
        _transfer(address(this), ecosystemTreasury, releasable);
        emit TokensReleased(ecosystemTreasury, releasable);
    }

    // Ecosystem Treasury 릴리즈 가능한 토큰 계산 함수
    function _calculateEcosystemReleasableAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 timeSinceTGE = block.timestamp - tgeDate;

        if (timeSinceTGE < schedule.cliffDuration) {
            return 0;  // 클리프 기간 동안 릴리즈 불가
        }

        uint256 totalReleasable = schedule.initialRelease;  // 초기 릴리즈

        // 클리프 이후 30일 간격으로 릴리즈되는 토큰 계산
        if (timeSinceTGE >= schedule.cliffDuration) {
            uint256 periodsPassed = (timeSinceTGE - schedule.cliffDuration) / 30 days;
            uint256 additionalReleasable = periodsPassed * (3_000_000 * 10**18);
            totalReleasable += additionalReleasable;
        }

        if (totalReleasable > schedule.totalAmount) {
            totalReleasable = schedule.totalAmount;
        }

        return totalReleasable - schedule.released;
    }
}
